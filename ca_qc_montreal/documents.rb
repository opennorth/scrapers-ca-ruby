class Montreal
  MAXIMUM_ATTEMPTS = 5

  def scrape_documents
    [
      {
        organization_id: 'ocd-organization/country:ca/cd:2466/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,86001600&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85945578&_dad=portal&_schema=PORTAL',
        start_year: 2001,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/executive_committee',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85931607&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:ahuntsic-cartierville/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85975614&_dad=portal&_schema=PORTAL',
        start_year: 2002,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:anjou/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979752&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:côte-des-neiges~notre-dame-de-grâce/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979770&_dad=portal&_schema=PORTAL',
        start_year: 2002,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:lachine/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,94713725&_dad=portal&_schema=PORTAL',
        start_year: 2010,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:lasalle/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8337,92865582&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:le_plateau-mont-royal/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979854&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:le_sud-ouest/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979873&_dad=portal&_schema=PORTAL',
        start_year: 2001,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:l~île-bizard~sainte-geneviève/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979888&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:mercier~hochelaga-maisonneuve/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=9417,114237611&_dad=portal&_schema=PORTAL',
        start_year: 2013,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:montréal-nord/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8717,97161614&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:outremont/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8517,95571598&_dad=portal&_schema=PORTAL',
        start_year: 2010,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:pierrefonds-roxboro/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981570&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:rivière-des-prairies~pointe-aux-trembles/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981591&_dad=portal&_schema=PORTAL',
        start_year: 2002,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:rosemont~la_petite-patrie/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981600&_dad=portal&_schema=PORTAL',
        start_year: 2008,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:saint-laurent/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,87943635&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:saint-léonard/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981609&_dad=portal&_schema=PORTAL',
        start_year: 2007,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:verdun/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8637,96027668&_dad=portal&_schema=PORTAL',
        start_year: 2011,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:ville-marie/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981620&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        organization_id: 'ocd-organization/country:ca/csd:2466023/borough:villeray~saint-michel~parc-extension/council',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8638,96045899&_dad=portal&_schema=PORTAL',
        start_year: 2003,
      },
    ].each do |source|
      source[:start_year].upto(Time.now.year) do |year|
        url = "#{source[:url]}&dateDebut=#{year}"

        page_number = 1
        loop do
          doc = Nokogiri::HTML(client.get(url).env[:raw_body].force_encoding('iso-8859-1').encode('utf-8'))

          doc.css('table[width="525"][cellpadding="5"]').each do |table|
            table.css('sup').remove # interrupts timestamps

            date, description = table.at_css('.eDarkGrey10Bold').inner_html.gsub(/[[:space:]]+/, ' ').split('<br>')

            table.css('a[href^="/sel"]').each do |a|
              # The city website is flaky.
              attempts = 0
              begin
                attempts += 1
                pdf_url = URI.escape(client.head("http://ville.montreal.qc.ca#{a[:href]}").env[:response_headers][:location]) # Faraday won't follow redirects
              rescue Timeout::Error
                if attempts < MAXIMUM_ATTEMPTS
                  duration = 2 ** attempts
                  warn("Timeout on http://ville.montreal.qc.ca#{a[:href]}, retrying in #{duration} (#{attempts}/#{MAXIMUM_ATTEMPTS})")
                  sleep duration
                  retry
                else
                  error("Timeout on http://ville.montreal.qc.ca#{a[:href]}, skipping")
                  next
                end
              end

              document = Document.new({
                date: date,
                description: description,
                title: a.text.strip,
                organization_id: source[:organization_id],
              })
              document.add_source(pdf_url, note: 'Ville de Montréal')
              dispatch(document)
              warn(document.errors.full_messages) if document.invalid?
            end
          end

          a = doc.at_css(%(a[title="#{page_number += 1}"]))
          if a
            url = a[:href]
          else
            break
          end
        end
      end
    end
  end

  def download
    store = DownloadStore.new(File.expand_path('downloads', Dir.pwd))
    connection.raw_connection['documents'].find.each do |document|
      source_url = document['sources'][0]['url']
      name = File.basename(source_url)

      unless store.exist?(name)
        store.write(name, get(source_url))
      end

      properties = {'byte_size' => store.size(name)}
      unless `which pdfinfo`.empty?
        number_of_pages = Integer(`pdfinfo downloads/CE_ODJ_ORDI_2007-08-29_09h00_FR.pdf`.match(/^Pages: +(\d+)$/)[1])
        properties['number_of_pages'] = number_of_pages
      end
      connection.raw_connection['documents'].find(document).update(document.merge(properties))
    end
  end
end
