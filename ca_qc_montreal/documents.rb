class Montreal
  MAXIMUM_ATTEMPTS = 5

  def scrape_documents
    [
      {
        key: 'agglomeration/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,86001600&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        key: 'ville/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85945578&_dad=portal&_schema=PORTAL',
        start_year: 2001,
      },
      {
        key: 'ville/comite_executif',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85931607&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        key: 'ahuntsic-cartierville/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85975614&_dad=portal&_schema=PORTAL',
        start_year: 2002,
      },
      {
        key: 'anjou/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979752&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        key: 'côte-des-neiges-notre-dame-de-grâce/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979770&_dad=portal&_schema=PORTAL',
        start_year: 2002,
      },
      {
        key: 'lachine/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,94713725&_dad=portal&_schema=PORTAL',
        start_year: 2010,
      },
      {
        key: 'lasalle/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8337,92865582&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        key: 'le_plateau-mont-royal/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979854&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        key: 'le_sud-ouest/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979873&_dad=portal&_schema=PORTAL',
        start_year: 2001,
      },
      {
        key: 'l~île-bizard-sainte-geneviève/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85979888&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        key: 'mercier-hochelaga-maisonneuve/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=9417,114237611&_dad=portal&_schema=PORTAL',
        start_year: 2013,
      },
      {
        key: 'montréal-nord/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8717,97161614&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        key: 'outremont/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8517,95571598&_dad=portal&_schema=PORTAL',
        start_year: 2010,
      },
      {
        key: 'pierrefonds-roxboro/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981570&_dad=portal&_schema=PORTAL',
        start_year: 2006,
      },
      {
        key: 'rivière-des-prairies-pointe-aux-trembles/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981591&_dad=portal&_schema=PORTAL',
        start_year: 2002,
      },
      {
        key: 'rosemont-la_petite-patrie/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981600&_dad=portal&_schema=PORTAL',
        start_year: 2008,
      },
      {
        key: 'saint-laurent/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,87943635&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        key: 'saint-léonard/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981609&_dad=portal&_schema=PORTAL',
        start_year: 2007,
      },
      {
        key: 'verdun/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8637,96027668&_dad=portal&_schema=PORTAL',
        start_year: 2011,
      },
      {
        key: 'ville-marie/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=5798,85981620&_dad=portal&_schema=PORTAL',
        start_year: 2009,
      },
      {
        key: 'villeray-saint-michel-parc-extension/conseil',
        url: 'http://ville.montreal.qc.ca/portal/page?_pageid=8638,96045899&_dad=portal&_schema=PORTAL',
        start_year: 2003,
      },
    ].each do |source|
      organization_id = organization_ids.fetch(source[:key])

      source[:start_year].upto(Time.now.year) do |year|
        url = "#{source[:url]}&dateDebut=#{year}"

        page_number = 1
        loop do
          doc = Nokogiri::HTML(client.get(url).env[:raw_body].force_encoding('iso-8859-1').encode('utf-8'))

          doc.css('table[width="525"][cellpadding="5"]').each do |table|
            table.css('sup').remove # interrupts timestamps

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

              date, description = table.at_css('.eDarkGrey10Bold').inner_html.gsub(/[[:space:]]+/, ' ').split('<br>')
              document = Document.new({
                date: date,
                description: description,
                title: a.text.strip,
                organization_id: organization_id,
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

  def pdf_to_text
    store = DownloadStore.new(File.expand_path('downloads', Dir.pwd))
    Pupa.session['documents'].find.each do |document|
      document = Document.new(document)
      name = File.basename(document.source_url)

      unless store.exist?(name)
        value = get(document.source_url)
        store.write(name, value)
      end

      value = `pdftotext -enc UTF-8 #{store.path(name)} - 2>&1`
      store.write("#{File.basename(name, File.extname(name))}.txt", value)
    end
  end
end
