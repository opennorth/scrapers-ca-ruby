class Montreal
  def scrape_people # should have 103
    gender_map = {
      'Madame' => 'female',
      'Monsieur' => 'male',
    }

    party_ids = {}
    { 'cm'  => 'Coalition Montréal - Marcel Côté',
      'ea'  => 'Équipe Anjou',
      'ebt' => 'Équipe Barbe Team - Pro action LaSalle',
      'eco' => 'Équipe conservons Outremont',
      'edc' => 'Équipe Denis Coderre pour Montréal',
      'edl' => 'Équipe Dauphin Lachine',
      'erb' => 'Équipe Richard Bélanger',
      'ind' => 'Indépendant',
      'pm'  => 'Projet Montréal',
      'vcm' => 'Vrai changement pour Montréal',
    }.each do |key,name|
      party_ids[key] = create_organization({
        name: name,
        classification: 'political party',
      })
    end

    response = client.get('http://ville.montreal.qc.ca/pls/portal/PORTALCON.ELUS_MUNICIPAUX_DATA.LISTE_ELUS')
    # @todo Remove `gsub` once file is corrected. (&#151; is an em-dash in Windows-1252.)
    data = Oj.load(response.env[:raw_body].force_encoding('windows-1252').encode('utf-8').gsub(/&#0?151;/, '—'))

    designated_councillor_number        = 1
    executive_committee_member_number   = 1
    agglomeration_council_member_number = 1

    # If any memberships seem to be missing, check the latest news.
    # @see http://election-montreal.qc.ca/actualites/index.en.html
    data.each do |row|
      row.each do |key,value|
        row[key] = value.strip
      end

      # @todo Remove once file is corrected. ("La Petite-Patrie" should have a hyphen, not an en dash.)
      row['ARRONDISSEMENT'].sub!('–', '-')
      # (Email addresses should not have a space after "@".)
      row['COURRIEL'].gsub!(' ', '')
      # (All records should set APPELLATION_POLITESSE.)
      row['APPELLATION_POLITESSE'] = 'Monsieur' if row['PRENOM'] == 'Jean-Dominic' && row['NOM'] == 'Lévesque-René'

      # @note Certaines personnes occupent deux postes de conseillers soit :
      #   1) le poste pour lequel ils ont été élus
      #   2) le poste de conseiller désigné à l’arrondissement Ville-Marie
      # @see http://donnees.ville.montreal.qc.ca/dataset/bd-elus
      person = Pupa::Person.new({
        honorific_prefix: row['APPELLATION_POLITESSE'],
        name: "#{row['PRENOM']} #{row['NOM']}",
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
      person.add_source('http://donnees.ville.montreal.qc.ca/fiche/bd-elus/', note: 'Portail des données ouvertes de la Ville de Montréal')

      # Dispatch the three people who appear twice and their party memberships only once.
      if row['TITRE_MAIRIE'] == 'Maire' || ['Conseiller de la Ville désigné', 'Conseillère de la Ville désignée'].include?(row['TITRE_CONSEIL'])
        properties = {person: person.fingerprint}
      else
        properties = {person_id: person._id}
        dispatch(person)
        warn(person.errors.full_messages) if person.invalid?
        create_membership(properties.merge(organization_id: party_ids.fetch(row['PARTI_POLITIQUE'])))

        # @todo Remove once file is corrected. (TITRE_MAIRIE and TITRE_CONSEIL should correspond to APPELLATION_POLITESSE.)
        hash = if person.gender == 'male'
          {
            'TITRE_MAIRIE' => /Maire\b/,
            'TITRE_CONSEIL' => 'Conseiller',
          }
        else
          {
            'TITRE_MAIRIE' => 'Mairesse',
            'TITRE_CONSEIL' => 'Conseillère',
          }
        end
        hash.each do |key,pattern|
          unless row[key].empty? || row[key][pattern]
            error("#{key} (#{row[key]}) doesn't agree with gender: #{person.to_h}")
          end
        end
      end

      # The mayor of Montreal has an `ARRONDISSEMENT` of "Ville de Montréal",
      # which will raise a `KeyError` if we perform the lookup eagerly.
      borough_council_ids = Hash.new do |hash,key|
        hash[key] = organization_ids.fetch("#{boroughs_by_name.fetch(key)}/conseil")
      end

      # Inherit the post's role and label.
      case row['TITRE_CONSEIL']
      when 'Conseiller de la Ville', 'Conseillère de la Ville' # should have 64 (borough mayors included)
        if row['TITRE_MAIRIE'][/\AMaire/]
          role = person.gender == 'male' ? "Maire d'arrondissement" : "Mairesse d'arrondissement"
          post_role = "Maire d'arrondissement"
          area_name = row['ARRONDISSEMENT']
        else
          role = person.gender == 'male' ? "Conseiller de ville" : "Conseillère de ville"
          post_role = "Conseiller de ville"
          area_name = '' # @todo Once the district is added to the file.
        end

        organization_id = organization_ids.fetch('ville/conseil')
        create_membership(properties.merge({
          role: role,
          organization_id: organization_id,
          post: {
            foreign_keys: {
              organization_id: organization_id,
            },
            role: post_role,
            area: {
              name: area_name,
            },
          },
        }))

        organization_id = borough_council_ids[row['ARRONDISSEMENT']]
        create_membership(properties.merge({
          role: role,
          organization_id: organization_id,
          post: {
            foreign_keys: {
              organization_id: organization_id,
            },
            role: post_role,
            area: {
              name: area_name,
            },
          },
        }))
      when "Conseiller d'arrondissement", "Conseillère d'arrondissement" # should have 38
        organization_id = borough_council_ids[row['ARRONDISSEMENT']]
        create_membership(properties.merge({
          role: row['TITRE_CONSEIL'],
          organization_id: organization_id,
          post: {
            foreign_keys: {
              organization_id: organization_id,
            },
            role: "Conseiller d'arrondissement",
            area: {
              name: '', # @todo Once the district is added to the file.
            },
          },
        }))
      # The two people who are designated councillors appear twice.
      when 'Conseiller de la Ville désigné', 'Conseillère de la Ville désignée' # should have 2
        create_membership(properties.merge({
          role: person.gender == 'male' ? 'Conseiller de ville désigné' : 'Conseillère de ville désignée',
          organization_id: organization_ids.fetch('ville-marie/conseil'),
          post: {
            label: "Conseiller de ville désigné (siège #{designated_councillor_number})",
          },
        }))
        designated_councillor_number += 1
      when ''
        # The person who is city mayor and Ville-Marie mayor appears twice.
        if row['TITRE_MAIRIE'] == "Maire" # should have 1
          create_membership(properties.merge({
            role: person.gender == 'male' ? "Maire de la Ville de Montréal" : "Mairesse de la Ville de Montréal",
            organization_id: organization_ids.fetch('ville/conseil'),
            post: {
              label: "Maire de la Ville de Montréal",
            },
          }))
        elsif row['TITRE_MAIRIE'] == "Maire d'arrondissement" && row['ARRONDISSEMENT'] == 'Ville-Marie' # should have 1
          create_membership(properties.merge({
            role: person.gender == 'male' ? "Maire d'arrondissement" : "Mairesse d'arrondissement",
            organization_id: organization_ids.fetch('ville-marie/conseil'),
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
          organization_id: organization_ids.fetch('ville/comite_executif'),
          post: {
            label: row['TITRE_COMITE_EXECUTIF'],
          },
        }))
      when 'Membre du comité exécutif', 'Vice-président du comité exécutif', 'Vice-présidente du comité exécutif'
        create_membership(properties.merge({
          label: row['TITRE_COMITE_EXECUTIF'],
          organization_id: organization_ids.fetch('ville/comite_executif'),
          post: {
            label: "Membre du comité exécutif (siège #{executive_committee_member_number})",
          },
        }))
        executive_committee_member_number += 1
      when 'Conseiller associé', 'Conseillère associée', ''
        # Do nothing.
      else
        error("Unrecognized TITRE_COMITE_EXECUTIF #{row['TITRE_COMITE_EXECUTIF']}")
      end

      row['AUTRE_TITRE'].split("\r\n").each do |title|
        if title == "Membre du conseil d'agglomération." # Ignore others.
          create_membership(properties.merge({
            label: "Membre du conseil d'agglomération",
            organization_id: organization_ids.fetch('agglomeration/conseil'),
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
    membership.add_source('http://donnees.ville.montreal.qc.ca/fiche/bd-elus/', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(membership)
  end
end
