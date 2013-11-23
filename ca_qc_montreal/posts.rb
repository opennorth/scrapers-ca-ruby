class Montreal
  def scrape_posts # should have 170
    # @see http://donnees.ville.montreal.qc.ca/dataset/elections-2009-postes-electifs
    unzip('http://donnees.ville.montreal.qc.ca/storage/f/2013-10-06T17%3A19%3A14.469Z/elections-2009-postes-electifs.zip') do |zipfile|
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
          label.gsub!(/\?|–/, '—') # en dash to em dash
          if borough_number == 21
            borough_number = 12
          end
          if borough_number == 7 && role == "Conseiller d'arrondissement"
            role = "Conseiller de ville"
          end

          if label[/\AMair/]
            label = label.sub(/\AMairie\b/, 'Maire')
            # @todo Remove the "?" after "Mairi" once file is corrected.
            area_name = label.sub(/\bdu\b/, 'de Le').match(/\AMairi?e de l(?:'arrondissement|a Ville) d(?:'|e )(.+?)\z/).captures.fetch(0).strip
          else
            label_suffix = label.match(/\A(?:Conseiller de ville arrondissement|District électoral)(.+?)(?:\(Pierrefonds-Roxboro\))?\z/).captures.fetch(0).strip
            label = "#{role} #{label_suffix}"
            area_name = label_suffix.match(/\Ad(?:'|e |e l'|e la |u )(.+?)(?: \(.+\))?\z/).captures.fetch(0).strip
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
            key = boroughs_by_number[borough_number]
            create_post(properties.merge(organization_id: organization_ids.fetch("#{key}/conseil")))
          end
        end

        properties = {
          organization_id: organization_ids.fetch('ville-marie/conseil'),
          area: {
            name: 'Ville-Marie',
          }
        }

        # @see http://election-montreal.qc.ca/cadre-electoral-districts/cadre-electoral/arrondissements/villemarie.en.html
        create_post(properties.merge({
          label: "Maire de l'arrondissement de Ville-Marie",
          role: "Maire d'arrondissement",
        }))
        create_post(properties.merge({
          label: "Conseiller de ville désigné (siège 1)",
          role: "Conseiller de ville désigné",
        }))
        create_post(properties.merge({
          label: "Conseiller de ville désigné (siège 2)",
          role: "Conseiller de ville désigné",
        }))
      else
        error('CSV file not found')
      end
    end
  end

  def create_post(properties)
    post = Pupa::Post.new(properties)
    post.add_source('http://donnees.ville.montreal.qc.ca/fiche/elections-2009-postes-electifs/', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(post)
  end
end
