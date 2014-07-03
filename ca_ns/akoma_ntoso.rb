class NovaScotia
  def akoma_ntoso
    Time.zone = 'Atlantic Time (Canada)'

    store = DownloadStore.new(File.expand_path('akoma_ntoso', Dir.pwd))

    connection.raw_connection[:debates].find.sort(docDate_date: 1).each do |debate|
      name = "#{debate.fetch('docNumber')}.an"

      people = {}
      connection.raw_connection[:speeches].find(debate_id: debate.fetch('_id'), element: 'speech', from_id: {'$ne' => nil}).each do |speech|
        id = speech.fetch('from_id')
        unless people.key?(id)
          url = connection.raw_connection[:people].find(_id: id).first.fetch('sources')[0].fetch('url')
          # @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Person
          part = url.match(%r{/([^/]+)/?\z})[1].downcase.gsub(/[._-]+/, '.').gsub(/[^a-z.]/, '')
          # `from` is only null for the speaker in the middle of a debate.
          people[id] = {'href' => "/ontology/person/ca.#{part}", 'showAs' => speech['from']}
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
                people.each do |id,speaker|
                  xml.TLCPerson(id: id, href: speaker.fetch('href'), showAs: speaker.fetch('showAs'))
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
              section = nil
              speeches = []

              connection.raw_connection[:speeches].find(debate_id: debate.fetch('_id')).sort(index: 1).each do |speech|
                if speech['element'] == 'heading'
                  unless speeches.empty?
                    output_section(xml, section, speeches)
                    speeches = []
                  end
                  section = speech
                elsif section
                  speeches << speech
                else # first few speeches
                  output_speech(xml, speech)
                end
              end

              unless speeches.empty?
                output_section(xml, section, speeches)
              end
            end
          end
        end
      end

      store.write(name, builder.to_xml)
    end
  end

private

  def output_section(xml, section, speeches)
    # <questions id="">
    #   <heading>ORAL QUESTIONS PUT BY MEMBERS</heading>
    #   <subheading>WAIT TIMES - EFFECTS</subheading>
    # </questions>
    # <resolutions id="">
    #   <heading>NOTICES OF MOTION UNDER RULE 32(3)</heading>
    #   <num title="1227">RESOLUTION NO. 1227</num>
    # </resolutions>
    # `name` and `id` are required attributes, but we don't care.
    # @todo Reflect more of the hierarchy from the table of contents.
    xml.debateSection do
      text = section.fetch('text')
      if section['num_title']
        xml.num(title: section.fetch('num_title')) do
          xml << text
        end
      else
        # `id` is a required attribute, but we don't care.
        xml.heading text
      end
      speeches.each do |speech|
        output_speech(xml, speech)
      end
    end
  end

  # @todo Use from_as, to_as
  def output_speech(xml, speech)
    attributes = {}
    # Anonymous speeches will not set `from_id`.
    if speech['from_id']
      attributes[:by] = "##{speech['from_id']}"
    end
    if speech['to_id'] # @todo check if ever null
      attributes[:to] = "##{speech['to_id']}"
    end

    unless speech['note'] == 'division'
      text = speech.fetch('text')
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
      xml.answer(attributes) do
        if speech['from'] # @todo check if ever null
          xml.from speech.fetch('from')
        end
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

    when 'question'
      # <question by="#foo" to="#bar">
      #   <from>MR. FOO</from>
      #   <p>Baz?</p>
      # </question>
      xml.question(attributes) do
        if speech['from'] # @todo check if ever null
          xml.from speech.fetch('from')
        end
        xml << text
      end

    when 'recordedTime'
      # <recordedTime time="2014-04-04T07:09:00-03:00">7:09 a.m.</recordedTime>
      xml.recordedTime(time: Time.zone.parse(speech.fetch('time')).strftime('%FT%T%:z')) do
        xml << text
      end

    when 'speech'
      if speech['note'] == 'resolution'
        xml.speech(attributes) do
          if speech['from']
            xml.from speech.fetch('from')
          end
          xml << text
        end
      else
        xml.speech(attributes) do
          # The only unattributed speeches are by the speaker.
          xml.from speech.fetch('from', 'MR. SPEAKER')
          xml << text
        end
      end

    else
      # @see http://examples.akomantoso.org/categorical.html#voteAttsAG
      if speech['note'] == 'division'
        # @todo
      else
        error("Unexpected element #{speech['element']}\n#{JSON.pretty_generate(speech)}")
      end
    end
  end
end
