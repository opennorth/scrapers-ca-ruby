class Montreal
  # @todo Replace once ocd-identifier-ids has a source for borough numbers.
  ARRONDISSEMENT_TYPE_IDS = %w(
    ahuntsic-cartierville
    anjou
    côte-des-neiges-notre-dame-de-grâce
    lachine
    lasalle
    le_plateau-mont-royal
    le_sud-ouest
    l~île-bizard-sainte-geneviève
    mercier-hochelaga-maisonneuve
    montréal-nord
    outremont
    pierrefonds-roxboro
    rivière-des-prairies-pointe-aux-trembles
    rosemont-la_petite-patrie
    saint-laurent
    saint-léonard
    verdun
    ville-marie
    villeray-saint-michel-parc-extension
  )

  def scrape_posts # should have 170
    organization_ids = scrape_organizations

    unzip('http://depot.ville.montreal.qc.ca/elections-2009-postes-electifs/data.zip') do |zipfile|
      entry = zipfile.entries.find{|entry| File.extname(entry.name) == '.csv'}
      if entry
        data = zipfile.read(entry).force_encoding('windows-1252').encode('utf-8')
        CSV.parse(data, headers: true, col_sep: ';') do |row|
          borough_number = row['no'].split('.').first.to_i
          role = row['type']
          label = row['poste']

          # @todo Remove once file is corrected.
          role.sub!('Conseillier', 'Conseiller')
          label.sub!('du dentre', 'du Centre')
          if borough_number == 21
            borough_number = 12
          end
          if borough_number == 7 && role == "Conseiller d'arrondissement"
            role = "Conseiller de ville"
          end

          if label[/\AMair/]
            area_name = label.sub(/\bdu\b/, 'de Le').match(/\AMairi?e de l(?:'arrondissement|a Ville) d(?:'|e )(.+?)\z/).captures.fetch(0).strip
          else
            label_suffix = label.match(/\A(?:Conseiller de ville arrondissement|District électoral)(.+?)(?:\(Pierrefonds-Roxboro\))?\z/).captures.fetch(0).strip
            area_name = label_suffix.match(/\Ad(?:'|u |e (?:l(?:'|a ))?)(.+?)(?: \(.+\))?\z/).captures.fetch(0).strip
            label = "#{role} #{label_suffix}"
          end

          properties = {
            label: label,
            role: role,
            area: {
              name: area_name,
            },
          }

          if ["Maire de la Ville de Montréal", "Maire d'arrondissement", "Conseiller de ville"].include?(role)
            create_post(properties.merge(organization_id: organization_ids.fetch('ville/conseil')))
          end

          if ["Maire d'arrondissement", "Conseiller de ville", "Conseiller d'arrondissement"].include?(role)
            # @todo Replace once ocd-identifier-ids has a source for borough numbers.
            key = ARRONDISSEMENT_TYPE_IDS[borough_number - 1]
            create_post(properties.merge(organization_id: organization_ids.fetch("#{key}/conseil")))
          end
        end

        properties = {
          role: 'Conseiller de ville désigné',
          organization_id: organization_ids.fetch('ville-marie/conseil'),
          area: {
            name: 'Ville-Marie',
          }
        }

        # @see http://election-montreal.qc.ca/cadre-electoral-districts/cadre-electoral/arrondissements/villemarie.en.html
        create_post(properties.merge({
          label: "Maire de l'arrondissement de Ville-Marie",
        }))
        create_post(properties.merge({
          label: "Conseiller de ville désigné (siège 1)",
        }))
        create_post(properties.merge({
          label: "Conseiller de ville désigné (siège 2)",
        }))
      else
        error('CSV file not found')
      end
    end
  end

  def create_post(properties, organization_id)
    post = Pupa::Post.new(properties)
    post.add_source('http://donnees.ville.montreal.qc.ca/fiche/elections-2009-postes-electifs/', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(post)
  end
end
