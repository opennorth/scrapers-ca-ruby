class NovaScotia
  def akoma_ntoso
    Time.zone = 'Atlantic Time (Canada)'

    store = if ENV['AWS_BUCKET'] && ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      AWSStore.new('akoma_ntoso', ENV['AWS_BUCKET'], ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
    else
      DownloadStore.new(File.expand_path('akoma_ntoso', Dir.pwd))
    end

    connection.raw_connection[:debates].find.sort(docDate_date: -1).each do |debate|
      debate_id = debate.fetch('_id')
      docDate_date = debate.fetch('docDate_date')
      docNumber = debate.fetch('docNumber')

      if @options.key?('up-to') && docDate_date > @options['up-to'] || @options.key?('down-to') && docDate_date < @options['down-to']
        info("Skipping #{docDate_date}")
        next
      end

      # docNumber is unique, and docDate is not. However, SayIt requires
      # filenames to be date-based.
      name = "#{docDate_date}_#{docNumber}.xml"

      if store.exist?(name) && @options.key?('no-clobber')
        info("Skipping #{name}")
        next
      end

      # Create a list of people for the <meta> block.
      @people = {}
      connection.raw_connection[:speeches].find(debate_id: debate_id, from_id: {'$ne' => nil}).sort(index: 1).each do |speech|
        id = speech.fetch('from_id')
        unless @people.key?(id)
          url = connection.raw_connection[:people].find(_id: id).first.fetch('sources')[0].fetch('url')
          # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Person
          part = url.match(%r{([^/]+)\z})[1].downcase.gsub(/[._-]+/, '.').gsub(/[^a-z.]/, '')
          # @see https://groups.google.com/d/topic/akomantoso-xml/I8vsYM3srv0/discussion
          @people[id] = {id: part, href: "/ontology/person/ca-ns.#{part}", showAs: speech.fetch('from')}
        end
      end
      connection.raw_connection[:speeches].find(debate_id: debate_id, to_id: {'$ne' => nil}).sort(index: 1).each do |speech|
        id = speech.fetch('to_id')
        unless @people.key?(id)
          url = connection.raw_connection[:people].find(_id: id).first.fetch('sources')[0].fetch('url')
          # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Person
          part = url.match(%r{([^/]+)\z})[1].downcase.gsub(/[._-]+/, '.').gsub(/[^a-z.]/, '')
          # @see https://groups.google.com/d/topic/akomantoso-xml/I8vsYM3srv0/discussion
          @people[id] = {id: part, href: "/ontology/person/ca-ns.#{part}", showAs: speech.fetch('to')}
        end
      end

      # Create a list of roles for the <meta> block.
      roles = {}
      connection.raw_connection[:speeches].find(debate_id: debate_id, from_as: {'$ne' => nil}, from: {'$ne' => nil}).sort(index: 1).each do |speech|
        id = speech.fetch('from_as')
        unless roles.key?(id)
          # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Role
          roles[id] = {href: "/ontology/role/nslegislature.ca-ns.#{id}", showAs: speech.fetch('from')}
        end
      end

      builder = Nokogiri::XML::Builder.new do |xml|
        # <akomaNtoso>
        #   <debate name="hansard">
        #     <meta>
        #       <references source="#source">
        #         <TLCOrganization id="source" href="/ontology/organization/ca.open.north.inc" showAs="Open North Inc.">
        #       </references>
        #     </meta>
        #     <preface>
        #       <docTitle>Debates, 1 May 2014</docTitle>
        #       <docNumber>14-38</docNumber>
        #       <docDate date="2014-05-01">Thursday, May 1, 2014</docDate>
        #       <docAuthority>Nova Scotia House of Assembly</docAuthority>
        #       <legislature value="62">62nd General Assembly</legislature>
        #       <session value="1">1st Session</session>
        #     </preface>
        #     <debateBody>
        #     </debateBody>
        #   </debate>
        # </akomaNtoso>
        xml.akomaNtoso do
          xml.debate(name: debate.fetch('name')) do
            xml.meta do
              xml.references(source: '#source') do
                # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Organization
                xml.TLCOrganization(id: 'source', href: '/ontology/organization/ca.open.north.inc', showAs: "Open North Inc.")
                @people.each do |id,person|
                  xml.TLCPerson(id: person.fetch(:id), href: person.fetch(:href), showAs: person.fetch(:showAs))
                end
                roles.each do |id,role|
                  xml.TLCRole(id: id, href: role.fetch(:href), showAs: role.fetch(:showAs))
                end
              end
            end
            xml.preface do
              xml.docTitle debate.fetch('docTitle')
              xml.docNumber docNumber
              xml.docDate(date: docDate_date) do
                xml << debate.fetch('docDate')
              end
              # @see https://groups.google.com/d/topic/akomantoso-xml/kh2t5i8OuHg/discussion
              xml.docAuthority debate.fetch('docAuthority')
              xml.legislature(value: debate.fetch('legislature_value')) do
                xml << debate.fetch('legislature')
              end
              xml.session(value: debate.fetch('session_value')) do
                xml << debate.fetch('session')
              end
              xml.link(rel: 'alternate', type: 'text/html', href: debate['sources'][0]['url'])
            end

            xml.debateBody do
              heading_level_1 = nil
              heading_level_2 = nil
              speeches_level_1 = []
              speeches_level_2 = []
              previous_speech = nil

              connection.raw_connection[:speeches].find(debate_id: debate_id).sort(index: 1).each do |speech|
                # If a recess isn't brief, it occurs between top-level sections.
                # A short recess may occur before a committee of the full house.
                if speech['element'] == 'narrative' && speech['text']['The House recessed.'] && !previous_speech['text'][/\b(?:five|brief)\b/]
                  # Append the second-level section to its top-level section.
                  # `speeches_level_2` only grows if `heading_level_2` is set.
                  if heading_level_2
                    speeches_level_1 << [heading_level_2, speeches_level_2]
                    speeches_level_2 = []
                  end
                  # Output the top-level section.
                  # `speeches_level_1` only grows if `heading_level_1` is set.
                  if heading_level_1
                    output_section(xml, heading_level_1, speeches_level_1)
                    speeches_level_1 = []
                  end
                  heading_level_1 = nil
                  heading_level_2 = nil

                  # Don't forget to output the narrative.
                  output_speech(xml, speech)

                elsif speech['element'] == 'heading'
                  if TOP_LEVEL_HEADINGS.include?(speech.fetch('text'))
                    if heading_level_2
                      speeches_level_1 << [heading_level_2, speeches_level_2]
                      speeches_level_2 = []
                    end
                    if heading_level_1
                      output_section(xml, heading_level_1, speeches_level_1)
                      speeches_level_1 = []
                    end
                    heading_level_1 = speech
                    heading_level_2 = nil

                  elsif heading_level_1.nil?
                    error("A level 2 heading occurs without a level 1 heading\n#{JSON.pretty_generate(speech)}")

                  # `heading_level_2` is only set if `heading_level_1` is set.
                  else
                    if heading_level_2
                      speeches_level_1 << [heading_level_2, speeches_level_2]
                      speeches_level_2 = []
                    end
                    heading_level_2 = speech
                  end

                # A non-heading speech.
                elsif heading_level_2
                  speeches_level_2 << speech
                elsif heading_level_1
                  speeches_level_1 << speech

                # The first few speeches in a hansard and the speeches after the
                # Lieutenant Governor's arrival have no section.
                else
                  output_speech(xml, speech)
                end

                previous_speech = speech
              end

              if heading_level_2
                speeches_level_1 << [heading_level_2, speeches_level_2]
                speeches_level_2 = []
              end
              if heading_level_1
                # Top-level section headings won't cause `output_section` to return.
                output_section(xml, heading_level_1, speeches_level_1)
              end
            end
          end
        end
      end

      if store.exist?(name)
        info("Overwriting #{name}")
      else
        info("Writing #{name}")
      end
      store.write(name, builder.to_xml)
    end
  end

private

  BILL_HEADING_RE = /\ABill (?:No\. )?\d+ [–-]/

  def output_section(xml, heading, speeches, list_of_bills = nil)
    text = heading.fetch('text')

    # An empty section.
    if speeches.empty?
      # Bills occasionally appear as a list without speeches, in contexts where
      # speeches are expected, e.g. after "would you please call".
      if text[BILL_HEADING_RE]
        return [heading]
      # Merge headings that are split onto two lines. The hansard includes top-
      # level headings, even if there is no content; we don't include these.
      elsif !TOP_LEVEL_HEADINGS.include?(text)
        return text
      end

    # The end of a list of bills.
    elsif list_of_bills
      if text[BILL_HEADING_RE]
        list_of_bills << heading
        list_of_bills.each do |speech|
          # Restore the bold tags from the source document.
          speech['text'] = "<b>#{speech.fetch('text')}</b>"
          speech['element'] = 'other'
          output_speech(xml, speech)
        end
        speeches.each do |speech|
          output_speech(xml, speech)
        end
      else
        error("Expected an end to the list of bills: #{speech}")
      end

    # An actual section.
    else
      tag = HEADING_TO_TAG[text] || :debateSection

      # <questions id="">
      #   <heading id="">ORAL QUESTIONS PUT BY MEMBERS</heading>
      # </questions>
      # @note `id` is a required attribute on debate sections. `name` is an
      #   additional required attributes on `debateSection`.
      xml.send(tag) do |section|
        if heading['num_title']
          xml.num(title: heading.fetch('num_title')) do
            xml << text
          end
        else
          # @note `id` is a required attribute.
          xml.heading text
        end

        adjustment = nil
        speeches.each do |speech|
          # If we saw the start of a list of bills, we expect a section whose
          # heading is a bill.
          if Array === adjustment
            if Array === speech
              bill = output_section(section, speech[0], speech[1], adjustment)
              if Array === bill # Continuation of a list of bills.
                adjustment += bill
              elsif bill # Continuation of a heading.
                error("A continuation of a heading occurs in a list of bills: #{bill}")
              else
                adjustment = nil
              end
            else
              error("Expected a continuation of the list of bills: #{adjustment}")
            end

          # If we saw the start of a heading, we expect a section whose heading
          # is a continuation of the heading.
          elsif adjustment
            if Array === speech
              speech[0]['text'] = "#{adjustment} #{speech[0].fetch('text')}"
              adjustment = output_section(section, speech[0], speech[1])
              if adjustment
                error("A continuation of a heading occurs twice in a row: #{adjustment}")
              end
            else
              error("Expected a continuation of the heading: #{adjustment}")
            end

          # A section, as a two-value array of heading and speeches.
          elsif Array === speech
            adjustment = output_section(section, speech[0], speech[1])

          # A speech.
          else
            output_speech(xml, speech)
          end
        end

        if adjustment
          error("Unhandled adjustment: #{adjustment}")
        end
      end
    end

    nil
  end

  def output_speech(xml, speech)
    # Tabular divisions have no text.
    if speech['text'] || !speech['division']
      text = speech.fetch('text')
      # Wrap a one-line speech in a paragraph.
      unless text['</p>']
        text = "<p>#{text}</p>"
      end
      if speech['element'] == 'narrative'
        text.gsub!(/\bCWH?\b/, 'Committee of the Whole House')
      end
    end

    case speech['element']
    when 'answer'
      # <answer by="#bar" to="#foo">
      #   <from>MS. BAR</from>
      #   <p>Yes.</p>
      # </answer>
      xml.answer(by: "##{by(speech)}", to: "##{to(speech)}") do
        xml.heading speech.fetch('heading')
        xml.from speech.fetch('from')
        xml << text
      end

    when 'narrative'
      # <narrative>
      #   <p>The Speaker and the Clerks left the Chamber.</p>
      #   <p>The Lieutenant Governor and his escorts left the Chamber preceded by the Sergeant-at-Arms.</p>
      # </narrative>
      xml.narrative do
        xml << text
      end

    when 'other'
      # <other>
      #   <p>Tabled May 1, 2014</p>
      # </other>
      xml.other do
        xml << text
      end

    when 'question'
      attributes = {}

      # Question to a post, like the Premier, will not set `to_id`.
      if speech['to_id']
        attributes[:to] = "##{to(speech)}"
      end

      # <question by="#foo" to="#bar">
      #   <from>MR. FOO</from>
      #   <p>Baz?</p>
      # </question>
      xml.question(attributes.merge(by: "##{by(speech)}")) do
        xml.num(title: speech.fetch('num_title')) do
          xml << speech.fetch('num')
        end
        xml.from speech.fetch('from')
        xml << text
      end

    when 'speech'
      attributes = {}

      # Three resolutions set neither.
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14apr02/
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec05/
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov14/
      if speech['from_id']
        attributes[:by] = "##{by(speech)}"
      elsif speech['from_as']
        # @see https://groups.google.com/forum/#!topic/akomantoso-xml/3R7EZRNp4No/discussion
        attributes[:by] = ''
        attributes[:as] = "##{speech['from_as']}"
        attributes[:status] = 'undefined'
      end

      # <speech by="#">
      #   <num title="1227">RESOLUTION NO. 1588</num>
      #   <from>Mr. Chuck Porter</from>
      #   <p>I hereby give notice that on a future day I shall move the adoption of the following resolution:</p>
      # </speech>
      xml.speech(attributes) do
        if speech['num_title']
          xml.num(title: speech.fetch('num_title')) do
            xml << speech.fetch('num')
          end
        end

        # Insert a <from> tag for the speaker, even if the source omits it.
        if speech['from']
          xml.from speech['from']
        elsif speech['from_as'] == 'speaker'
          xml.from 'MR. SPEAKER'
        end

        xml << text
      end

    when 'subheading'
      # <subheading>(RESPONSES)</subheading>
      xml.subheading speech.fetch('text')

    else
      # @note `id` is a required attribute on `other`.
      # @see http://examples.akomantoso.org/categorical.html#voteAttsAG
      if speech['division']
        if speech['html']['<table']
          doc = Nokogiri::XML(speech['html'].gsub('<br>', '<br/>'), &:noblanks)
          doc.xpath('//td[string-length(text())=1]').each do |td|
            td.inner_html = ''
          end
          doc.xpath('//table/@class').remove

          xml.other do
            xml << doc.to_xhtml(indent: 0)
          end
        else
          xml.other do
            xml << text
          end
        end
      else
        error("Unexpected element #{speech['element']}\n#{JSON.pretty_generate(speech)}")
      end
    end
  end

  def by(speech)
    @people.fetch(speech.fetch('from_id')).fetch(:id)
  end

  def to(speech)
    @people.fetch(speech.fetch('to_id')).fetch(:id)
  end
end
