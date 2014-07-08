class NovaScotia
  def akoma_ntoso
    Time.zone = 'Atlantic Time (Canada)'

    store = DownloadStore.new(File.expand_path('akoma_ntoso', Dir.pwd))

    connection.raw_connection[:debates].find.sort(docDate_date: 1).each do |debate|
      # docNumber is unique, and docDate is not. However, SayIt requires
      # filenames to be date-based.
      name = "#{debate.fetch('docDate_date')}_#{debate.fetch('docNumber')}.xml"

      # Create a list of people for the <meta> block.
      people = {}
      connection.raw_connection[:speeches].find(debate_id: debate.fetch('_id'), from_id: {'$ne' => nil}).each do |speech|
        id = speech.fetch('from_id')
        unless people.key?(id)
          url = connection.raw_connection[:people].find(_id: id).first.fetch('sources')[0].fetch('url')
          # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Person
          part = url.match(%r{([^/]+)\z})[1].downcase.gsub(/[._-]+/, '.').gsub(/[^a-z.]/, '')
          # @see https://groups.google.com/d/topic/akomantoso-xml/I8vsYM3srv0/discussion
          people[id] = {'href' => "/ontology/person/ca-ns.#{part}", 'showAs' => speech.fetch('from')}
        end
      end

      # Create a list of roles for the <meta> block.
      roles = {}
      connection.raw_connection[:speeches].find(debate_id: debate.fetch('_id'), from_as: {'$ne' => nil}, from: {'$ne' => nil}).each do |speech|
        id = speech.fetch('from_as')
        unless roles.key?(id)
          # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Role
          roles[id] = {'href' => "/ontology/role/nslegislature.ca-ns.#{id}", 'showAs' => speech.fetch('from')}
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
        #       <docProponent>Nova Scotia House of Assembly</docProponent>
        #       <legislature value="62">62nd General Assembly</legislature>
        #       <session value="1">1st Session</session>
        #     </preface>
        #     <debateBody>
        #     </debateBody>
        #   </debate>
        # </akomaNtoso>
        xml.akomaNtoso do
          xml.debate(name: 'hansard') do
            xml.meta do
              xml.references(source: '#source') do
                # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Organization
                xml.TLCOrganization(id: 'source', href: '/ontology/organization/ca.open.north.inc', showAs: "Open North Inc.")
                people.each do |id,person|
                  xml.TLCPerson(id: id, href: person.fetch('href'), showAs: person.fetch('showAs'))
                end
                roles.each do |id,role|
                  xml.TLCRole(id: id, href: role.fetch('href'), showAs: role.fetch('showAs'))
                end
              end
            end
            xml.preface do
              xml.docTitle debate.fetch('docTitle')
              xml.docNumber debate.fetch('docNumber')
              xml.docDate(date: debate.fetch('docDate_date')) do
                xml << debate.fetch('docDate')
              end
              # docAuthority and FRBRWork are other options.
              # @see https://groups.google.com/d/topic/akomantoso-xml/kh2t5i8OuHg/discussion
              # @see https://groups.google.com/d/topic/akomantoso-xml/I8vsYM3srv0/discussion
              # @see http://www.akomantoso.org/release-notes/akoma-ntoso-3.0-schema/naming-conventions-1/bungenihelpcenterreferencemanualpage.2008-01-09.1484954524
              xml.docProponent debate.fetch('docProponent')
              xml.legislature(value: debate.fetch('legislature_value')) do
                xml << debate.fetch('legislature')
              end
              xml.session(value: debate.fetch('session_value')) do
                xml << debate.fetch('session')
              end
            end

            xml.debateBody do
              heading_level_1 = nil
              heading_level_2 = nil
              speeches_level_1 = []
              speeches_level_2 = []

              connection.raw_connection[:speeches].find(debate_id: debate.fetch('_id')).sort(index: 1).each do |speech|
                if speech['element'] == 'heading'
                  if TOP_LEVEL_HEADINGS.include?(speech.fetch('text'))
                    unless heading_level_2.nil?
                      speeches_level_1 << [heading_level_2, speeches_level_2]
                      speeches_level_2 = []
                    end
                    unless heading_level_1.nil?
                      output_section(xml, heading_level_1, speeches_level_1)
                      speeches_level_1 = []
                    end
                    heading_level_1 = speech
                    heading_level_2 = nil
                  elsif heading_level_1.nil?
                    error('Level 2 heading occurs without a level 1 heading')
                    warn("speech:\n#{JSON.pretty_generate(speech)}")
                  else
                    unless heading_level_2.nil?
                      speeches_level_1 << [heading_level_2, speeches_level_2]
                      speeches_level_2 = []
                    end
                    heading_level_2 = speech
                  end
                elsif heading_level_2
                  speeches_level_2 << speech
                elsif heading_level_1
                  speeches_level_1 << speech
                else # first few speeches
                  output_speech(xml, speech)
                end
              end

              unless heading_level_1.nil?
                output_section(xml, heading_level_1, speeches_level_1)
              end
            end
          end
        end
      end

      info("Writing #{name}")
      store.write(name, builder.to_xml)
    end
  end

private

  def output_section(xml, heading, speeches)
    text = heading.fetch('text')

    # The hansard always includes top-level headings, even if there is no
    # content; we don't include these. Merge headings that are split onto
    # two lines, unless the heading begins with "Bill No.".
    if speeches.empty? && !text[/\ABill (?:No\. )?\d+ [–-]/]
      unless TOP_LEVEL_HEADINGS.include?(text)
        return text
      end
    else
      tag = HEADING_TO_TAG[text] || :debateSection

      # <questions id="">
      #   <heading id="">ORAL QUESTIONS PUT BY MEMBERS</heading>
      #   <subheading>WAIT TIMES - EFFECTS</subheading>
      # </questions>
      # @note `id` is a required attribute on debate sections. `name` is an
      # additional required attributes on `debateSection`.
      xml.send(tag) do |section|
        if heading['num_title']
          xml.num(title: heading.fetch('num_title')) do
            xml << text
          end
        else
          # @note `id` is a required attribute.
          xml.heading text
        end

        text_to_merge = nil
        speeches.each do |speech|
          if text_to_merge
            if Array === speech
              subheading = speech[0]
              subheading['text'] = "#{text_to_merge} #{subheading.fetch('text')}"
              output_section(section, subheading, speech[1])
            else
              error("Expected a continuation of the heading: #{text_to_merge}")
            end
          elsif Array === speech
            text_to_merge = output_section(section, speech[0], speech[1])
          else
            output_speech(xml, speech)
          end
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
    end

    case speech['element']
    when 'answer'
      # <answer by="#bar" to="#foo">
      #   <from>MS. BAR</from>
      #   <p>Yes.</p>
      # </answer>
      xml.answer(by: "##{speech.fetch('from_id')}", to: "##{speech.fetch('to_id')}") do
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
        attributes[:to] = "##{speech['to_id']}"
      end

      # <question by="#foo" to="#bar">
      #   <from>MR. FOO</from>
      #   <p>Baz?</p>
      # </question>
      xml.question(attributes.merge(by: "##{speech.fetch('from_id')}")) do
        xml.from speech.fetch('from')
        xml << text
      end

    when 'recordedTime'
      # Skip for now, as it's an inline element that is not supported by SayIt,
      # plus it adds nothing to the user experience, like page numbers which we
      # could include with the <eop> tag.
      return

      # <recordedTime time="2014-04-04T07:09:00-03:00">7:09 a.m.</recordedTime>
      xml.recordedTime(time: Time.zone.parse(speech.fetch('time')).strftime('%FT%T%:z')) do
        xml << text
      end

    when 'speech'
      attributes = {}

      # Three resolutions set neither.
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14apr02/
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec05/
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov14/
      if speech['from_id']
        attributes[:by] = "##{speech['from_id']}"
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

    else
      # @note `id` is a required attribute on `other`.
      # @see http://examples.akomantoso.org/categorical.html#voteAttsAG
      if speech['division']
        if speech['html']['<table']
          doc = Nokogiri::XML(speech['html'], &:noblanks)
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
end
