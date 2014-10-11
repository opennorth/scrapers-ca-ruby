class Montreal
  MAIRE_DE_LA_VILLE = 'Maire de la Ville'

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
      boroughs[row[1]] = row[0].sub(/\Aocd-division\b/, 'ocd-organization')
    end

    gender_map = {
      'Madame' => 'female',
      'Monsieur' => 'male',
    }

    party_ids = {}
    [ 'Coalition Montréal - Marcel Côté',
      'Équipe Anjou',
      'Équipe Barbe Team – Pro action LaSalle', # n-dash
      'Équipe conservons Outremont',
      'Équipe Denis Coderre pour Montréal',
      'Équipe Dauphin Lachine',
      'Équipe Richard Bélanger',
      'Indépendant',
      'Projet Montréal - Équipe Bergeron',
      'Vrai changement pour Montréal - Groupe Mélanie Joly',
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

    designated_councillor_number        = 1
    executive_committee_member_number   = 1
    agglomeration_council_member_number = 1

    # If any memberships seem to be missing, check the latest news.
    # @see http://election-montreal.qc.ca/actualites/index.en.html
    # @see http://donnees.ville.montreal.qc.ca/dataset/bd-elus
    get('http://ville.montreal.qc.ca/pls/portal/PORTALCON.ELUS_MUNICIPAUX_DATA.LISTE_ELUS').each do |row|
      row.each do |key,value|
        row[key] = value.strip
      end

      # @todo Remove once file is corrected.
      { "L'Île-Bizard-Sainte-Geneviève" => "L'Île-Bizard—Sainte-Geneviève", # m-dash
        'Côte-des-Neiges-Notre-Dame-de-Grâce' => 'Côte-des-Neiges—Notre-Dame-de-Grâce', # m-dash
        'Mercier-Hochelaga-Maisonneuve' => 'Mercier—Hochelaga-Maisonneuve', # m-dash
        'Rivière-des-Prairies-Pointe-aux-Trembles' => 'Rivière-des-Prairies—Pointe-aux-Trembles', # m-dash
        'Rosemont–La Petite–Patrie' => 'Rosemont—La Petite-Patrie', # n-dashes to m-dash and hyphen
        'Villeray-Saint-Michel-Parc-Extension' => 'Villeray—Saint-Michel—Parc-Extension', # m-dashes
      }.each do |pattern,replacement|
        row['ARRONDISSEMENT'].sub!(pattern, replacement)
      end

      # @note Certaines personnes occupent deux postes de conseillers soit :
      #   1) le poste pour lequel ils ont été élus
      #   2) le poste de conseiller désigné à l’arrondissement Ville-Marie
      # @note TITRE_MAIRIE and TITRE_CONSEIL may not correspond to the person's
      #   gender, as the choice is at the discretion of the person (Marc Lebel,
      #   2 Dec 2013).
      name = "#{row['PRENOM']} #{row['NOM']}"
      person = Pupa::Person.new({
        honorific_prefix: row['APPELLATION_POLITESSE'],
        name: name,
        family_name: row['NOM'],
        given_name: row['PRENOM'],
        email: row['COURRIEL'],
        image: row['FICHIER_IMAGE'],
        gender: gender_map.fetch(row['APPELLATION_POLITESSE']),
      })
      person.add_contact_detail('email', row['COURRIEL'])
      person.add_contact_detail('address', row['ADRESSE_ARRONDISSEMENT'], note: 'Arrondissement')
      person.add_contact_detail('address', row['ADRESSE_HOTEL_DE_VILLE'], note: 'Hôtel de ville')
      person.add_contact_detail('voice', row['TELEPHONE_ARRONDISSEMENT'], note: 'Arrondissement')
      person.add_contact_detail('voice', row['TELEPHONE_HOTEL_DE_VILLE'], note: 'Hôtel de ville')
      person.add_contact_detail('fax', row['TELECOPIE_ARRONDISSEMENT'], note: 'Arrondissement')
      person.add_contact_detail('fax', row['TELECOPIE_HOTEL_DE_VILLE'], note: 'Hôtel de ville')
      person.add_source('http://donnees.ville.montreal.qc.ca/dataset/bd-elus', note: 'Portail des données ouvertes de la Ville de Montréal')

      # Dispatch the three people who appear twice and their party memberships only once.
      if row['TITRE_MAIRIE'] == MAIRE_DE_LA_VILLE || ['Conseiller de la Ville désigné', 'Conseillère de la Ville désignée'].include?(row['TITRE_CONSEIL'])
        properties = {person: person.fingerprint}
      else
        properties = {person_id: person._id}
        dispatch(person)
        warn(person.errors.full_messages) if person.invalid? # No consequence unless major errors.
        create_membership(properties.merge(organization_id: party_ids.fetch(row['PARTI_POLITIQUE'])))
      end

      identifier = if row['TITRE_MAIRIE'] == MAIRE_DE_LA_VILLE
        '0,00'
      elsif row['TITRE_MAIRIE'] == "Maire d'arrondissement" && row['ARRONDISSEMENT'] == 'Ville-Marie'
        '18,00'
      else
        identifiers.fetch(name)
      end

      # Inherit the post's role and label.
      case row['TITRE_CONSEIL']
      when 'Conseiller de la Ville', 'Conseillère de la Ville' # should have 64 (borough mayors included)
        if row['TITRE_MAIRIE'][/\AMaire/]
          role = person.gender == 'male' ? "Maire d'arrondissement" : "Mairesse d'arrondissement"
          post_role = "Maire d'arrondissement"
        else
          role = person.gender == 'male' ? "Conseiller de ville" : "Conseillère de ville"
          post_role = "Conseiller de ville"
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

        organization_id = "#{boroughs.fetch(row['ARRONDISSEMENT'])}/council"
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
      when "Conseiller d'arrondissement", "Conseillère d'arrondissement" # should have 38
        organization_id = "#{boroughs.fetch(row['ARRONDISSEMENT'])}/council"
        create_membership(properties.merge({
          role: row['TITRE_CONSEIL'],
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
      # The two people who are designated councillors appear twice.
      when 'Conseiller de la Ville désigné', 'Conseillère de la Ville désignée' # should have 2
        create_membership(properties.merge({
          role: person.gender == 'male' ? 'Conseiller de ville désigné' : 'Conseillère de ville désignée',
          organization_id: 'ocd-organization/country:ca/csd:2466023/borough:ville-marie/council',
          post: {
            label: "Conseiller de ville désigné (siège #{designated_councillor_number})",
          },
        }))
        designated_councillor_number += 1
      when ''
        # The person who is city mayor and Ville-Marie mayor appears twice.
        if row['TITRE_MAIRIE'] == MAIRE_DE_LA_VILLE # should have 1
          create_membership(properties.merge({
            role: person.gender == 'male' ? "Maire de la Ville de Montréal" : "Mairesse de la Ville de Montréal",
            organization_id: 'ocd-organization/country:ca/csd:2466023/council',
            post: {
              label: "Maire de la Ville de Montréal",
            },
          }))
        elsif row['TITRE_MAIRIE'] == "Maire d'arrondissement" && row['ARRONDISSEMENT'] == 'Ville-Marie' # should have 1
          create_membership(properties.merge({
            role: person.gender == 'male' ? "Maire d'arrondissement" : "Mairesse d'arrondissement",
            organization_id: 'ocd-organization/country:ca/csd:2466023/borough:ville-marie/council',
            post: {
              label: "Maire de l'arrondissement de Ville-Marie",
            },
          }))
        else
          error("Unrecognized membership #{JSON.dump(row)}")
        end
      else
        error("Unrecognized TITRE_CONSEIL #{row['TITRE_CONSEIL']}")
      end

      case row['TITRE_COMITE_EXECUTIF']
      when 'Président du comité exécutif'
        create_membership(properties.merge({
          label: row['TITRE_COMITE_EXECUTIF'],
          organization_id: 'ocd-organization/country:ca/csd:2466023/executive_committee',
          post: {
            label: row['TITRE_COMITE_EXECUTIF'],
          },
        }))
      when 'Membre du comité exécutif', 'Vice-président du comité exécutif', 'Vice-présidente du comité exécutif'
        create_membership(properties.merge({
          label: row['TITRE_COMITE_EXECUTIF'],
          organization_id: 'ocd-organization/country:ca/csd:2466023/executive_committee',
          post: {
            label: "Membre du comité exécutif (siège #{executive_committee_member_number})",
          },
        }))
        executive_committee_member_number += 1
      when 'Conseiller associé', 'Conseillère associée', 'Président du conseil de la Ville', 'Vice-présidente du conseil de la Ville', ''
        # Do nothing.
      else
        warn("Unrecognized TITRE_COMITE_EXECUTIF #{row['TITRE_COMITE_EXECUTIF']}") # Add to above exceptions.
      end

      row['AUTRE_TITRE'].split("\r\n").each do |title|
        if title == "Membre du conseil d'agglomération." # Ignore others.
          create_membership(properties.merge({
            label: "Membre du conseil d'agglomération",
            organization_id: 'ocd-organization/country:ca/cd:2466/council',
            post: {
              label: "Membre du conseil d'agglomération (siège #{agglomeration_council_member_number})",
            },
          }))
        end
      end

      # AUTRE_TITRE_OFFICIEL has been previously unpredictable.
      #   "Leader de la majorité"
      #   "Leader de l'opposition"
      #   "Chef de l'opposition"

      # COMMISSION_CONSEIL is always blank. RESPONSABILITES is unpredicatable.
    end
  end

  def create_membership(properties)
    membership = Pupa::Membership.new(properties)
    membership.add_source('http://donnees.ville.montreal.qc.ca/dataset/bd-elus', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(membership)
  end
end
