class Montreal
  def scrape_posts # should have 198
    # @see http://donnees.ville.montreal.qc.ca/dataset/elections-2013-postes-electifs
    CSV.parse(get('http://donnees.ville.montreal.qc.ca/storage/f/2014-01-06T16%3A29%3A28.760Z/electiongene-2013-posteselectifs.csv').force_encoding('utf-8'), headers: true) do |row|
      borough_number = row.fetch('no').split('.').first.to_i
      role = row.fetch('type')
      label = row.fetch('poste')

      # @todo Remove once file is corrected.
      label.sub!('du dentre', 'du Centre')
      label.gsub!(/\?|–/, '—') # en dash to em dash
      label.strip!

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

    # @see http://election-montreal.qc.ca/cadre-electoral-districts/cadre-electoral/arrondissements/villemarie.en.html
    properties = {
      organization_id: organization_ids.fetch('ville-marie/conseil'),
      area: {
        name: 'Ville-Marie',
      }
    }
    dispatch(Pupa::Post.new(properties.merge({
      label: "Maire de l'arrondissement de Ville-Marie",
      role: "Maire d'arrondissement",
    })))
    dispatch(Pupa::Post.new(properties.merge({
      label: "Conseiller de ville désigné (siège 1)",
      role: "Conseiller de ville désigné",
    })))
    dispatch(Pupa::Post.new(properties.merge({
      label: "Conseiller de ville désigné (siège 2)",
      role: "Conseiller de ville désigné",
    })))

    1.upto(11) do |n|
      dispatch(Pupa::Post.new({
        label: "Membre du comité exécutif (siège #{n})",
        role: 'Membre',
        organization_id: organization_ids.fetch('ville/comite_executif'),
      }))
    end

    dispatch(Pupa::Post.new({
      label: 'Président du comité exécutif',
      role: 'Président',
      organization_id: organization_ids.fetch('ville/comite_executif'),
    }))

    # The Mayor of Montreal and 15 members of municipal council.
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=5977,88851616&_dad=portal&_schema=PORTAL
    1.upto(16) do |n|
      dispatch(Pupa::Post.new({
        label: "Membre du conseil d'agglomération (siège #{n})",
        role: 'Membre',
        organization_id: organization_ids.fetch('agglomeration/conseil'),
      }))
    end
  end

  def create_post(properties)
    post = Pupa::Post.new(properties)
    post.add_source('http://donnees.ville.montreal.qc.ca/dataset/elections-2013-postes-electifs', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(post)
  end
end
