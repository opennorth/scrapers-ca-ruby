require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class Montreal < GovernmentProcessor
  # @todo Add districts (add to ocd-division-ids first).
  # @see http://www.mamrot.gouv.qc.ca/organisation-municipale/organisation-territoriale/instances-municipales/paliers-municipaux/
  # @see http://www.mamrot.gouv.qc.ca/pub/organisation_municipale/organisation_territoriale/organisation_municipale.pdf
  def scrape_organizations
    # @todo Move to people scraper?
    [ 'Vision Montréal',
      'Projet Montréal',
      'Indépendant',
    ].each do |name|
      create_organization({
        name: name,
        classification: 'political party',
      })
    end

    # The CMM has other suborganizations.
    # @see http://cmm.qc.ca/qui-sommes-nous/
    cmm = create_organization({
      name: 'Communauté métropolitaine de Montréal',
    })
    cmm_conseil = create_organization({
      name: 'Conseil de la Communauté',
      parent_id: cmm,
    })
    cmm_comite_executif = create_organization({
      name: 'Comité exécutif de la Communauté',
      parent_id: cmm_conseil,
    })

    # Whereas the administrative region of Montreal is a provincial organization
    # the agglomeration of Montreal is a municipal organization. Both cover the
    # same territory. In this case, we care only about municipal organizations.
    # @see http://fr.wikipedia.org/wiki/Montr%C3%A9al_(r%C3%A9gion_administrative)

    # The CRÉs (conférences régionales des élus) have no decision-making power.
    # @see http://fr.wikipedia.org/wiki/Conf%C3%A9rence_r%C3%A9gionale_des_%C3%A9lus

    # The agglomeration behaves like a municipalité régionale de comté (MRC). It
    # has other suborganizations.
    # @see http://ville.montreal.qc.ca/pls/portal/docs/page/prt_vdm_fr/media/documents/organigramme.pdf
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=5798,85513587&_dad=portal&_schema=PORTAL
    # @see http://www1.ville.montreal.qc.ca/banque311/recherche/categorie/62
    agglomeration = create_organization({
      _id: 'ocd-organization/country:ca/cd:2466', # todo swap for administrative region identifier?
      name: 'Agglomération de Montréal',
      parent_id: cmm,
    })
    agglomeration_council = create_organization({
      name: "Conseil d'agglomération",
      parent_id: agglomeration,
    })

    # The city has other suborganizations.
    # @see http://ville.montreal.qc.ca/portal/page?_pageid=6877,62465637&_dad=portal&_schema=PORTAL
    # @see http://www1.ville.montreal.qc.ca/banque311/recherche/categorie/62
    ville = create_organization({
      _id: 'ocd-organization/country:ca/csd:2466023',
      name: 'Ville de Montréal',
      parent_id: agglomeration,
    })
    ville_conseil = create_organization({
      name: 'Conseil municipal',
      parent_id: ville,
    })
    ville_comite_executif = create_organization({
      name: 'Comité exécutif',
      parent_id: ville_conseil,
    })

    CSV.parse(get('https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/census_subdivision-montreal-arrondissements.csv').force_encoding('UTF-8')) do |row|
      arrondissement = create_organization({
        _id: row[0].sub(/\Aocd-division/, 'ocd-organization'),
        name: row[1],
        parent_id: ville,
      })
      arrondissement_conseil = create_organization({
        name: "Conseil d'arrondissement",
        parent_id: arrondissement,
      })
    end
  end

  def create_organization(properties)
    organization = Pupa::Organization.new(properties)
    dispatch(organization)
    organization._id
  end

  def scrape_people
    # @todo http://donnees.ville.montreal.qc.ca/fiche/bd-elus/
  end
end

GovernmentProcessor.add_scraping_task(:organizations)
GovernmentProcessor.add_scraping_task(:people)

Pupa::Runner.new(Montreal, database: 'mycityhall', expires_in: 604800).run(ARGV) # 1 week
