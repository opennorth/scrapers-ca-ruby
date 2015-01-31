class Montreal
  def scrape_posts # should have 198
    boroughs = {}
    CSV.parse(get('https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/census_subdivision-montreal-boroughs.csv').force_encoding('utf-8'), headers: true) do |row|
      boroughs[row['id'].split(':')[-1]] = row['id'].sub(/\Aocd-division\b/, 'ocd-organization')
    end

    # @see http://donnees.ville.montreal.qc.ca/dataset/resultats-elections-2013
    get('http://donnees.ville.montreal.qc.ca/storage/f/2013-12-11T15%3A59%3A02.221Z/resultats-election-2013-finaux-sommaires.xml')['resultats']['resultats_postes']['poste'].each do |post|
      role = case post['nom']
      when /\AMaire de l'arrondissement\b/
        "Maire d'arrondissement"
      when /\AConseiller de la ville\b/
        "Conseiller de la ville"
      when /\AConseiller d'arrondissement\b/
        "Conseiller d'arrondissement"
      else
        error("Unrecognized label #{post['nom']}" )
      end

      label = post.fetch('nom')
      label.sub!(/\AConseiller d'arrondissement - District électoral\b/, "Conseiller d'arrondissement")
      label.sub!(/\AConseiller de la ville - District électoral\b/, "Conseiller de la ville")
      label.sub!(/\AConseiller de la ville arrondissement\b/, "Conseiller de la ville")
      label.gsub!('–', '—') # en dash to em dash
      label.gsub!('−', '—') # minus sign to em dash
      label.strip!

      area_name = post['district']['__content__'] || post['arrondissement']['__content__']
      area_name.gsub!('–', '—') # en dash to em dash
      identifier = post.fetch('id')

      unless label[area_name]
        warn("expected #{label} to match #{area_name}") # No consequence, just inconsistent.
      end

      properties = {
        label: label,
        role: role,
        area: {
          name: area_name,
        },
        identifiers: [{
          identifier: identifier,
        }],
      }

      if ["Maire d'arrondissement", "Conseiller de la ville"].include?(role)
        create_post(properties.merge(organization_id: 'ocd-organization/country:ca/csd:2466023/council'))
      end

      create_post(properties.merge(organization_id: "#{boroughs.fetch(identifier.split(',').first)}/council"))
    end

    # @see http://donnees.ville.montreal.qc.ca/dataset/elections-2013-postes-electifs
    dispatch(Pupa::Post.new({
      label: "Maire de la Ville de Montréal",
      role: "Maire de la Ville de Montréal",
      organization_id: 'ocd-organization/country:ca/csd:2466023/council',
      area: {
        name: 'Montréal',
      },
      identifiers: [{
        identifier: '0,00',
      }],
    }))

    # @see http://election-montreal.qc.ca/cadre-electoral-districts/cadre-electoral/arrondissements/villemarie.en.html
    properties = {
      organization_id: 'ocd-organization/country:ca/csd:2466023/borough:ville-marie/council',
      area: {
        name: 'Ville-Marie',
      },
    }
    dispatch(Pupa::Post.new(properties.merge({
      label: "Maire de l'arrondissement de Ville-Marie",
      role: "Maire d'arrondissement",
      identifiers: [{
        identifier: '18,00',
      }],
    })))
    dispatch(Pupa::Post.new(properties.merge({
      label: "Conseiller de la ville désigné (siège 1)",
      role: "Conseiller de la ville désigné",
    })))
    dispatch(Pupa::Post.new(properties.merge({
      label: "Conseiller de la ville désigné (siège 2)",
      role: "Conseiller de la ville désigné",
    })))

    # @see http://ville.montreal.qc.ca/portal/page?_pageid=5798,85931587&_dad=portal&_schema=PORTAL
    1.upto(11) do |n|
      dispatch(Pupa::Post.new({
        label: "Membre du comité exécutif (siège #{n})",
        role: 'Membre',
        organization_id: 'ocd-organization/country:ca/csd:2466023/executive_committee',
      }))
    end
    dispatch(Pupa::Post.new({
      label: 'Président du comité exécutif',
      role: 'Président',
      organization_id: 'ocd-organization/country:ca/csd:2466023/executive_committee',
    }))

    # The Mayor of Montreal and 15 members of municipal council.
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=5977,88851616&_dad=portal&_schema=PORTAL
    1.upto(16) do |n|
      dispatch(Pupa::Post.new({
        label: "Membre du conseil d'agglomération (siège #{n})",
        role: 'Membre',
        organization_id: 'ocd-organization/country:ca/cd:2466/council',
      }))
    end

    # @see http://cmm.qc.ca/who-are-we/council/
    1.upto(13) do |n|
      dispatch(Pupa::Post.new({
        label: "Membre du conseil de la Communauté métropolitaine de Montréal (siège #{n})",
        role: 'Membre',
        organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/council',
      }))
    end
    dispatch(Pupa::Post.new({
      label: 'Président de la Communauté métropolitaine de Montréal',
      role: 'Président',
      organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/council',
    }))

    # #see http://cmm.qc.ca/who-are-we/executive-committee/
    1.upto(3) do |n|
      dispatch(Pupa::Post.new({
        label: "Membre du comité exécutif de la Communauté métropolitaine de Montréal (siège #{n})",
        role: 'Membre',
        organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/executive_committee',
      }))
    end
    dispatch(Pupa::Post.new({
      label: 'Président du comité exécutif de la Communauté métropolitaine de Montréal',
      role: 'Président',
      organization_id: 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal/executive_committee',
    }))
  end

  def create_post(properties)
    post = Pupa::Post.new(properties)
    post.add_source('http://donnees.ville.montreal.qc.ca/dataset/resultats-elections-2013', note: 'Portail des données ouvertes de la Ville de Montréal')
    dispatch(post)
  end
end
