class Montreal
  # Returns the JSON IDs of scraped organizations, for use in other scraping tasks.
  #
  # @return [Hash] the JSON IDs of scraped organizations
  # @see http://www.mamrot.gouv.qc.ca/organisation-municipale/organisation-territoriale/instances-municipales/paliers-municipaux/
  # @see http://www.mamrot.gouv.qc.ca/pub/organisation_municipale/organisation_territoriale/organisation_municipale.pdf
  def scrape_organizations # should have 22 jurisdictions, 22 councils, 2 committees
    # The CMM has other suborganizations.
    # @see http://cmm.qc.ca/qui-sommes-nous/
    organization_ids['cmm'] = create_organization({
      name: 'Communauté métropolitaine de Montréal',
      classification: 'jurisdiction',
    })
    organization_ids['cmm/conseil'] = create_organization({ # 28 posts
      name: 'Conseil de la Communauté',
      parent_id: organization_ids.fetch('cmm'),
      classification: 'council',
    })
    organization_ids['cmm/comite_executif'] = create_organization({
      name: 'Comité exécutif de la Communauté',
      parent_id: organization_ids.fetch('cmm/conseil'),
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
    organization_ids['agglomeration'] = create_organization({
      _id: 'ocd-organization/country:ca/cd:2466',
      name: 'Agglomération de Montréal',
      parent_id: organization_ids.fetch('cmm'),
      classification: 'jurisdiction',
    })
    organization_ids['agglomeration/conseil'] = create_organization({ # 31 posts
      name: "Conseil d'agglomération",
      parent_id: organization_ids.fetch('agglomeration'),
      classification: 'council',
    })

    # The city has other suborganizations.
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=6877,62465637&_dad=portal&_schema=PORTAL
    # @see http://www1.ville.montreal.qc.ca/banque311/recherche/categorie/62
    organization_ids['ville'] = create_organization({
      _id: 'ocd-organization/country:ca/csd:2466023',
      name: 'Ville de Montréal',
      parent_id: organization_ids.fetch('agglomeration'),
      classification: 'jurisdiction',
    })
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=5798,85933591&_dad=portal&_schema=PORTAL
    organization_ids['ville/conseil'] = create_organization({
      name: 'Conseil municipal',
      parent_id: organization_ids.fetch('ville'),
      classification: 'council',
    })
    organization_ids['ville/comite_executif'] = create_organization({ # 12 posts
      name: 'Comité exécutif',
      parent_id: organization_ids.fetch('ville/conseil'),
      classification: 'committee',
    })

    CSV.parse(get('https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/census_subdivision-montreal-arrondissements.csv').force_encoding('UTF-8')) do |row|
      key = row[0].split(':').last
      organization_ids[key] = create_organization({
        _id: row[0].sub(/\Aocd-division/, 'ocd-organization'),
        name: row[1],
        parent_id: organization_ids.fetch('ville'),
        classification: 'jurisdiction',
      })
      subkey = "#{key}/conseil"
      organization_ids[subkey] = create_organization({
        name: "Conseil d'arrondissement",
        parent_id: organization_ids.fetch(key),
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
