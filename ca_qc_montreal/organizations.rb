class Montreal
  # Returns the JSON IDs of scraped organizations, for use in other scraping tasks.
  #
  # @return [Hash] the JSON IDs of scraped organizations
  # @see http://www.mamrot.gouv.qc.ca/organisation-municipale/organisation-territoriale/instances-municipales/paliers-municipaux/
  # @see http://www.mamrot.gouv.qc.ca/pub/organisation_municipale/organisation_territoriale/organisation_municipale.pdf
  def scrape_organizations # should have 46: 22 jurisdictions, 22 councils, 2 committees
    # The CMM has other suborganizations.
    # @see http://cmm.qc.ca/qui-sommes-nous/
    # @see http://www2.publicationsduquebec.gouv.qc.ca/dynamicSearch/telecharge.php?type=2&file=/C_37_01/C37_01.html
    region = 'ocd-organization/country:ca/region:communauté_métropolitaine_de_montréal'
    create_organization({
      _id: region,
      name: 'Communauté métropolitaine de Montréal',
      classification: 'jurisdiction',
    })
    create_organization({ # 28 posts
      _id: "#{region}/council",
      name: 'Conseil de la Communauté',
      parent_id: region,
      classification: 'council',
    })
    create_organization({ # 8 posts
      _id: "#{region}/executive_committee",
      name: 'Comité exécutif de la Communauté',
      parent_id: "#{region}/council",
      classification: 'committee',
    })

    # Whereas the administrative region of Montreal is a provincial organization
    # the agglomeration of Montreal is a municipal organization. Both cover the
    # same territory. In this case, we care only about municipal organization.
    # @see http://fr.wikipedia.org/wiki/Montr%C3%A9al_(r%C3%A9gion_administrative)

    # The CRÉs (conférences régionales des élus) have no decision-making power.
    # @see http://fr.wikipedia.org/wiki/Conf%C3%A9rence_r%C3%A9gionale_des_%C3%A9lus

    # The agglomeration behaves like a municipalité régionale de comté (MRC). It
    # has other suborganizations.
    # @see http://ville.montreal.qc.ca/pls/portal/docs/page/prt_vdm_fr/media/documents/organigramme.pdf
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=5798,85513587&_dad=portal&_schema=PORTAL
    # @see http://www1.ville.montreal.qc.ca/banque311/recherche/categorie/62
    census_division = 'ocd-organization/country:ca/cd:2466'
    create_organization({
      _id: census_division,
      name: 'Agglomération de Montréal',
      parent_id: region,
      classification: 'jurisdiction',
    })
    create_organization({ # 31 posts
      _id: "#{census_division}/council",
      name: "Conseil d'agglomération",
      parent_id: census_division,
      classification: 'council',
    })

    # The city has other suborganizations.
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=6877,62465637&_dad=portal&_schema=PORTAL
    # @see http://www1.ville.montreal.qc.ca/banque311/recherche/categorie/62
    census_subdivision = 'ocd-organization/country:ca/csd:2466023'
    create_organization({
      _id: census_subdivision,
      name: 'Ville de Montréal',
      parent_id: census_division,
      classification: 'jurisdiction',
    })
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=5798,85933591&_dad=portal&_schema=PORTAL
    create_organization({ # 65 posts
      _id: "#{census_subdivision}/council",
      name: 'Conseil municipal',
      parent_id: census_subdivision,
      classification: 'council',
    })
    create_organization({ # 12 posts
      _id: "#{census_subdivision}/executive_committee",
      name: 'Comité exécutif',
      parent_id: "#{census_subdivision}/council",
      classification: 'committee',
    })

    CSV.parse(get('https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/census_subdivision-montreal-arrondissements.csv').force_encoding('utf-8')) do |row|
      borough = row[0].sub(/\Aocd-division\b/, 'ocd-organization')
      create_organization({
        _id: borough,
        name: row[1],
        parent_id: census_subdivision,
        classification: 'jurisdiction',
      })
      create_organization({
        _id: "#{borough}/council",
        name: "Conseil d'arrondissement",
        parent_id: borough,
        classification: 'council',
      })
    end
  end

  def create_organization(properties)
    organization = Pupa::Organization.new(properties)
    dispatch(organization)
    organization._id
  end
end
