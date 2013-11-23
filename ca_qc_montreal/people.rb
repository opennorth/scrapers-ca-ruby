class Montreal
  def scrape_people # should have 103
    party_ids = {}
    { 'cm' => 'Coalition Montréal - Marcel Côté',
      'ea' => 'Équipe Anjou',
      'ebt' => 'Équipe Barbe Team - Pro action LaSalle',
      'eco' => 'Équipe conservons Outremont',
      'edc' => 'Équipe Denis Coderre pour Montréal',
      'edl' => 'Équipe Dauphin Lachine',
      'erb' => 'Équipe Richard Bélanger',
      'ind' => 'Indépendant',
      'pm' => 'Projet Montréal',
      'vcm' => 'Vrai changement pour Montréal',
    }.each do |key,name|
      party_ids[key] = create_organization({
        name: name,
        classification: 'political party',
      })
    end

    gender_map = {
      '' => nil,
      'Madame' => 'female',
      'Monsieur' => 'male',
    }

    response = client.get('http://ville.montreal.qc.ca/pls/portal/PORTALCON.ELUS_MUNICIPAUX_DATA.LISTE_ELUS')
    # @todo Remove `gsub` once file is corrected. (&#151; is an em-dash in Windows-1252.)
    data = Oj.load(response.env[:raw_body].force_encoding('windows-1252').encode('utf-8').gsub(/&#0?151;/, '—'))

    # @todo Are seats vacant? 1 Conseiller d'arrondissement, 3 Conseiller de la Ville [remove comment?]
    data.each do |row|
      row.each do |key,value|
        row[key] = value.strip
      end

      person = nil

      # @note Certaines personnes occupent deux postes de conseillers soit :
      #   1) le poste pour lequel ils ont été élus
      #   2) le poste de conseiller désigné à l’arrondissement Ville-Marie
      # @see http://donnees.ville.montreal.qc.ca/dataset/bd-elus
      unless ['Maire de la Ville', 'Conseiller de la Ville désigné', 'Conseillère de la Ville désignée'].include?(row['TITRE_CONSEIL'])
        person = Pupa::Person.new({
          honorific_prefix: row['APPELLATION_POLITESSE'],
          name: "#{row['PRENOM']} #{row['NOM']}",
          family_name: row['NOM'],
          given_name: row['PRENOM'],
          # @todo Remove `gsub` once file is corrected. (Email addresses should not have a space after "@".)
          email: row['COURRIEL'].gsub(' ', ''),
          image: row['FICHIER_IMAGE'],
          gender: gender_map.fetch(row['APPELLATION_POLITESSE']),
        })
        person.add_contact_detail('email', row['COURRIEL'])
        # @todo standardize format of addresses (remove HTML, strip each line, remove parens) (see handwritten notes)
        person.add_contact_detail('address', row['ADRESSE_ARRONDISSEMENT'], note: 'Arrondissement')
        person.add_contact_detail('address', row['ADRESSE_HOTEL_DE_VILLE'], note: 'Hôtel de ville')
        # @todo format phone numbers (see handwritten notes)
        person.add_contact_detail('voice', row['TELEPHONE_ARRONDISSEMENT'], note: 'Arrondissement')
        person.add_contact_detail('voice', row['TELEPHONE_HOTEL_DE_VILLE'], note: 'Hôtel de ville')
        person.add_contact_detail('fax', row['TELECOPIE_ARRONDISSEMENT'], note: 'Arrondissement')
        person.add_contact_detail('fax', row['TELECOPIE_HOTEL_DE_VILLE'], note: 'Hôtel de ville')
        person.add_source('http://donnees.ville.montreal.qc.ca/fiche/bd-elus/', note: 'Portail des données ouvertes de la Ville de Montréal')
        dispatch(person)
      end

      properties = if person
        {person_id: person._id}
      else
        {
          # @todo need to handle the three duplicates differently
        }
      end

      if person # If this is the first time processing this person.
        create_membership(properties.merge(organization_id: party_ids.fetch(row['PARTI_POLITIQUE'])))
      end

      # The mayor of Montreal has an `ARRONDISSEMENT` of "Ville de Montréal",
      # which will raise a `KeyError` if we perform the lookup eagerly.
      borough_council_ids = Hash.new do |hash,key|
        # @todo Remove `sub` once file is corrected. ("La Petite-Patrie" should have a hyphen, not an en dash.)
        hash[key] = organization_ids.fetch("#{boroughs_by_name.fetch(key.sub('–', '-'))}/conseil")
      end

      # Inherit the post's role and label.
      case row['TITRE_CONSEIL']
      when 'Conseiller de la Ville', 'Conseillère de la Ville' # should have 64
        create_membership(properties.merge({
          organization_id: organization_ids['ville/conseil'],
          post_id: '', # @todo
        }))

        create_membership(properties.merge({
          organization_id: borough_council_ids[row['ARRONDISSEMENT']],
          post_id: '', # @todo
        }))
      # The two people who are designated councillors appear twice.
      when 'Conseiller de la Ville désigné', 'Conseillère de la Ville désignée' # should have 2
        create_membership(properties.merge({
          organization_id: organization_ids.fetch('ville-marie/conseil'),
          post_id: '', # @todo
        }))
      when "Conseiller d'arrondissement", "Conseillère d'arrondissement" # should have 38
        create_membership(properties.merge({
          organization_id: borough_council_ids[row['ARRONDISSEMENT']],
          post_id: '', # @todo
        }))
      when ''
        # The person who is city mayor and Ville-Marie mayor appears twice.
        case row['TITRE_MAIRIE']
        when "Maire de la Ville" # should have 1
          create_membership(properties.merge({
            organization_id: organization_ids['ville/conseil'],
            post_id: '', # @todo
          }))
        when "Maire d'arrondissement" # should have 1
          if row['ARRONDISSEMENT'] == 'Ville-Marie'
            create_membership(properties.merge({
              organization_id: organization_ids.fetch('ville-marie/conseil'),
              post_id: '', # @todo
            }))
          else
            error("Unexpected ARRONDISSEMENT #{row['ARRONDISSEMENT']}")
          end
        end
      else
        error("Unrecognized TITRE_CONSEIL #{row['TITRE_CONSEIL']}")
      end

      if row['TITRE_COMITE_EXECUTIF']['exécutif'] && row['TITRE_MAIRIE'] != 'Maire de la Ville'
        create_membership(properties.merge({
          role: row['TITRE_COMITE_EXECUTIF'], # @todo remove role attribute, create posts for executive committee
          organization_id: organization_ids['ville/comite_executif'],
          post_id: '', # @todo
        }))
      end

      # @todo Remove once file is corrected. (TITRE_MAIRIE and TITRE_CONSEIL should correspond to APPELLATION_POLITESSE.)
      if person && person.gender # If this is the first time processing this person.
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

      # @todo test images

      # AUTRE_TITRE (80)
      #   CMM council
      #   Agglomeration council
      #   Agencies
      #   Committees
      #   Commissions
      #   Societies
      # AUTRE_TITRE_OFFICIEL (6)
      #   Chef de l'opposition
      #   Leader de l'opposition
      #   Président de commission
      #   Présidente de commission
      #   Vice-président de commission
      #   Vice-présidente de commission
      # RESPONSABILITES (20)

      # @note We don't have a post for "Président du conseil de la Ville", which
      # appears under TITRE_COMITE_EXECUTIF. We don't have posts for "Conseiller
      # associé" or "Conseillère associée" either.

      # COMMISSION_CONSEIL is always blank.
    end
  end

  def create_membership(properties)
    membership = Pupa::Membership.new(properties)
    membership.add_source('http://donnees.ville.montreal.qc.ca/fiche/bd-elus/', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(membership)
  end
end
