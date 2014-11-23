class Montreal
  # @note New datasets are now available. Waiting on:
  # * Publier les données sous format CSV
  # * Include le numéro de poste (par exemple, 1,00, 1,10, etc.)
  # * Mettre le bureau d'arrondissement dans son propre champs
  # * Mettre le numéro de téléphone d'arrondissement dans son propre champs
  # * Éliminer les préfixes "Tél:" et "Arr.:"
  # * Ajouter le URL pour la photo de la personne (FICHIER_IMAGE dans l'ancien jeu de données)
  # http://donnees.ville.montreal.qc.ca/dataset/listes-des-elus-de-la-ville-de-montreal
  # http://donnees.ville.montreal.qc.ca/dataset/listes-des-elus-du-conseil-d-agglomeration
  # http://donnees.ville.montreal.qc.ca/dataset/commissions-permanentes-du-conseil-membres
  def scrape_people # should have 103
    boroughs = {}
    rows = CSV.parse(get('https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/census_subdivision-montreal-boroughs.csv').force_encoding('utf-8'))
    rows.shift
    rows.each do |row|
      boroughs[row[3]] = row[0].sub(/\Aocd-division\b/, 'ocd-organization')
    end

    gender_map = {
      'Madame' => 'female',
      'Monsieur' => 'male',
    }

    party_ids = {}
    [ 'Coalition Montréal',
      'Indépendant',
      'Projet Montréal',
      'Vrai changement pour Montréal',
      'Équipe Anjou',
      'Équipe Barbe Team – Pro action LaSalle', # n-dash
      'Équipe Dauphin Lachine',
      'Équipe Denis Coderre pour Montréal',
      'Équipe Richard Bélanger',
      'Équipe conservons Outremont',
    ].each do |name|
      party_ids[name] = create_organization({
        name: name,
        classification: 'political party',
      })
    end

    # @see http://donnees.ville.montreal.qc.ca/dataset/resultats-elections-2013
    identifiers = {}
    get('http://donnees.ville.montreal.qc.ca/storage/f/2013-12-11T15%3A59%3A02.221Z/resultats-election-2013-finaux-sommaires.xml')['resultats']['resultats_postes']['poste'].each do |post|
      candidate = post['candidat'].find do |candidate|
        candidate['nb_voix_majorite']
      end

      family_name = UnicodeUtils.downcase(candidate['nom'], :fr).gsub(/(?<=\A|\bmc|[ '-])(.)/) do
        $1.capitalize
      end

      # @todo Remove once file is corrected.
      if family_name == 'Desousa'
        family_name = 'DeSousa'
      end
      given_name = candidate['prenom']
      if given_name == 'Dimitrios (Jim)'
        given_name = 'Dimitrios Jim'
      end
      name = "#{given_name} #{family_name}"
      if name == 'Laura Palestini'
        name = 'Laura-Ann Palestini'
      end

      identifiers[name] = post.fetch('id')
    end

    designated_councillor_number                       = 1
    executive_committee_member_number                  = 1
    agglomeration_council_member_number                = 1
    greater_montreal_council_member_number             = 1
    greater_montreal_executive_committee_member_number = 1

    # If any memberships seem to be missing, check the latest news.
    # @see http://election-montreal.qc.ca/actualites/index.en.html
    # @see http://donnees.ville.montreal.qc.ca/dataset/listes-des-elus-de-la-ville-de-montreal
    rows = CSV.parse(get('http://donnees.ville.montreal.qc.ca/dataset/9084d8ed-aceb-4fb6-be03-5fd0005f1bd1/resource/f01c434b-842c-4512-93c6-8c81e425c563/download/listeofficielledeselus.csv').force_encoding('utf-8'))
    data = CSV.generate do |csv|
      rows[4..-1].each do |row|
        csv << row
      end
    end
    CSV.parse(data, headers: true).each do |row|
      # @note A role may not correspond to the person's gender, as the choice is
      # at the discretion of the person (Marc Lebel, 2 Dec 2013).

      # Skip last rows.
      next if row['Nom'].nil?

      row.each do |key,value|
        row[key] = value && value.strip
      end

      name = "#{row.fetch('Prénom')} #{row.fetch('Nom')}"
      person = Pupa::Person.new({
        honorific_prefix: row.fetch('Appel'),
        name: name,
        family_name: row.fetch('Nom'),
        given_name: row.fetch('Prénom'),
        email: row.fetch('Courriel officiel'),
        gender: gender_map.fetch(row.fetch('Appel')),
      })
      person.add_contact_detail('email', row.fetch('Courriel officiel'))

      address = row.fetch('Bureau')
      parts = address.split(/(?=Arrondissement\b)/, 2).map do |address|
        address.lines[1..-1].join.strip
      end
      person.add_contact_detail('address', parts[0], note: address[/\AArrondissement\b/] ? 'Arrondissement' : 'Hôtel de ville')
      if parts[1]
        person.add_contact_detail('address', parts[1], note: 'Arrondissement')
      end

      voice = row.fetch('Téléphone ')
      parts = voice.split(/(?=(?:Arr|Tél?)\.?:)/).map do |voice|
        voice.sub(/(?:Arr|Tél?)\.?:/, '').strip
      end
      person.add_contact_detail('voice', parts[0], note: voice[/\AArr\.:/] ? 'Arrondissement' : 'Hôtel de ville')
      if parts[1]
        person.add_contact_detail('voice', parts[1], note: 'Arrondissement')
      end

      person.add_source('http://donnees.ville.montreal.qc.ca/dataset/listes-des-elus-de-la-ville-de-montreal', note: 'Portail des données ouvertes de la Ville de Montréal')

      properties = {person_id: person._id}
      dispatch(person)
      warn(person.errors.full_messages) if person.invalid? # No consequence unless major errors.
      create_membership(properties.merge(organization_id: party_ids.fetch(row.fetch('Parti').strip.sub(/\AIndépendante\z/, 'Indépendant'))))

      identifier = row.fetch('Poste').sub(/\A0/, '')
      number = identifier.split(',')[0]

      roles = row.fetch('Fonction').split(/\n|(?=Membre)/).map(&:strip).reject do |role|
        # Excludes opposition leaders, commissions, party leaders, associated
        # members, substitute mayors.
        # @see https://github.com/opennorth/scrapers-ca-ruby/issues/2
        role[/\b(?:Chef|Commission|Leader|associée?|caucus|suppléante?)\b/]
      end

      roles.each do |role|
        # Inherit the post's role and label.
        case role
        when 'Maire de la Ville de Montréal' # should have 1
          create_membership(properties.merge({
            role: role,
            organization_id: 'ocd-organization/country:ca/csd:2466023/council',
            post: {
              role: role,
            },
          }))

        when 'Conseiller de la ville', 'Conseillère de la ville', # should have 46
          "Maire d'arrondissement", "Mairesse d'arrondissement" # should have 18
          if role == "Maire de l'arrondissement de Ville-Marie"
            role = "Maire d'arrondissement"
          end

          # Post roles are masculine.
          if role[/\AMaire/]
            post_role = "Maire d'arrondissement"
          else
            post_role = 'Conseiller de la ville'
          end

          organization_id = 'ocd-organization/country:ca/csd:2466023/council'
          create_membership(properties.merge({
            role: role,
            organization_id: organization_id,
            post: {
              foreign_keys: {
                organization_id: organization_id,
              },
              role: post_role,
              identifiers: {
                identifier: identifier,
              },
            },
          }))

          organization_id = "#{boroughs.fetch(number)}/council"
          create_membership(properties.merge({
            role: role,
            organization_id: organization_id,
            post: {
              foreign_keys: {
                organization_id: organization_id,
              },
              role: post_role,
              identifiers: {
                identifier: identifier,
              },
            },
          }))
        when "Maire de l'arrondissement de Ville-Marie" # should have 1
          create_membership(properties.merge({
            role: person.gender == 'male' ? "Maire d'arrondissement" : "Mairesse d'arrondissement",
            organization_id: 'ocd-organization/country:ca/csd:2466023/borough:ville-marie/council',
            post: {
              label: "Maire de l'arrondissement de Ville-Marie",
            },
          }))
        when "Conseiller d'arrondissement", "Conseillère d'arrondissement" # should have 38
          organization_id = "#{boroughs.fetch(number)}/council"
          create_membership(properties.merge({
            role: role,
            organization_id: organization_id,
            post: {
              foreign_keys: {
                organization_id: organization_id,
              },
              role: "Conseiller d'arrondissement",
              identifiers: {
                identifier: identifier,
              },
            },
          }))
        when "Membre du conseil d'arrondissement de Ville-Marie" # should have 2
          create_membership(properties.merge({
            role: person.gender == 'male' ? 'Conseiller de la ville désigné' : 'Conseillère de la ville désignée',
            organization_id: 'ocd-organization/country:ca/csd:2466023/borough:ville-marie/council',
            post: {
              label: "Conseiller de la ville désigné (siège #{designated_councillor_number})",
            },
          }))
          designated_councillor_number += 1

        when 'Président du comité exécutif' # should have 1
          create_membership(properties.merge({
            label: role,
            organization_id: 'ocd-organization/country:ca/csd:2466023/executive_committee',
            post: {
              label: role,
            },
          }))
        when 'Membre du comité exécutif', # should have 11
          'Vice-président du comité exécutif', # not sure if post is stable
          'Vice-présidente du comité exécutif' # not sure if post is stable
          create_membership(properties.merge({
            label: role,
            organization_id: 'ocd-organization/country:ca/csd:2466023/executive_committee',
            post: {
              label: "Membre du comité exécutif (siège #{executive_committee_member_number})",
            },
          }))
          executive_committee_member_number += 1

        when "Membre du conseil d'agglomération", # should have 16
          "Président d'assemblée du conseil d'agglomération", # not sure if post is stable
          "Porte-parole au conseil d'agglomération" # not sure if post is stable
          create_membership(properties.merge({
            label: "Membre du conseil d'agglomération",
            organization_id: 'ocd-organization/country:ca/cd:2466/council',
            post: {
              label: "Membre du conseil d'agglomération (siège #{agglomeration_council_member_number})",
            },
          }))
          agglomeration_council_member_number += 1

        when 'Président de la Communauté métropolitaine de Montréal' # should have 1
          create_membership(properties.merge({
            label: role,
            organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/council',
            post: {
              label: role,
            },
          }))
        when 'Membre du Conseil de la Communauté métropolitaine de Montréal', # should have 13
          'Membre du Conseil de la communauté métropolitaine de Montréal'
          create_membership(properties.merge({
            label: "Membre du conseil de la Communauté métropolitaine de Montréal",
            organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/council',
            post: {
              label: "Membre du conseil de la Communauté métropolitaine de Montréal (siège #{greater_montreal_council_member_number})",
            },
          }))
          greater_montreal_council_member_number += 1

        when 'Président du comité exécutif de la Communauté métropolitaine de Montréal'
          create_membership(properties.merge({
            label: role,
            organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/executive_committee',
            post: {
              label: role,
            },
          }))
        when 'Membre du comité exécutif de la Communauté métropolitaine de Montréal',
          'Membre du comité exécutif Conseil de la Communauté métropolitaine de Montréal',
          'Membre du comité exécutif du Conseil de la Communauté métropolitaine de Montréal'
          create_membership(properties.merge({
            label: "Membre du comité exécutif de la Communauté métropolitaine de Montréal",
            organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/executive_committee',
            post: {
              label: "Membre du comité exécutif de la Communauté métropolitaine de Montréal (siège #{greater_montreal_executive_committee_member_number})",
            },
          }))
          greater_montreal_executive_committee_member_number += 1

        when 'Président du conseil municipal',
          'Vice-présidente du conseil municipal',
          'Membre de la Société de transport de Montréal',
          'Vice-président de la Société de transport de Montréal'
          # Do nothing
        else
          error("Unrecognized role #{role}")
        end
      end

      # Not using "Responsabilités".
    end
  end

  def create_membership(properties)
    membership = Pupa::Membership.new(properties)
    membership.add_source('http://donnees.ville.montreal.qc.ca/dataset/bd-elus', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(membership)
  end
end
