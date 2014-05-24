# @todo Find good documentation for URIs (use lowerCamelCase for committee, use ca-ns instead of country code)
# @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Organization
# @see http://www.akomantoso.org/release-notes/akoma-ntoso-3.0-schema/naming-conventions-1/bungenihelpcenterreferencemanualpage.2008-01-09.1484954524
# @todo Ask about https://github.com/mysociety/za-hansard/tree/master/za_hansard/importers
class NovaScotia
  def scrape_speeches
    Time.zone = 'Atlantic Time (Canada)'

    # @note Can extract the majority party, the assembly dates, and the session dates.
    doc = get('http://nslegislature.ca/index.php/proceedings/hansard/')
    doc.css('.latest .assembly a').each do |a|
      paginate(a)
    end

    doc.css('.previous .assembly dd').select do |dd|
      dd.text[/\d+\z/].to_i > 2011
    end.reverse.each do |dd|
      paginate(dd.at_css('a'))
    end
  end

private

  def paginate(list_a)
    begin
      # @note Can extract the page range and links to video, audio and PDF.
      href = list_a[:href]
      unless URI.parse(href).scheme
        href = "http://nslegislature.ca#{href}"
      end
      list = get(href)

      # This is the simplest place to extract these values.
      legislature_value, session_value = list.at_css('.tablePad h2').text.match(/Assembly (\d+), Session (\d+)/)[1..2].map{|x| Integer(x)}

      list.xpath('//tr[not(@style)]').reject do |tr|
        tr.at_css('td').text == ' ' || Date.parse(tr.at_css('a[href]')) < Date.new(2011, 11, 1) # non-breaking space
      end.each do |tr|
        @a = tr.at_css('a[href]')
        docDate_date = Date.parse(@a.text)

        # @note Can extract the speaker, the publisher, the printer, the table
        # of contents, the start time, the deputy speaker.
        doc = get(@a[:href])

        # The sitting on the list page can be incorrect. FIXME
        docNumber = doc.at_xpath('//p[@class="hansard_title"]/span[@class="alignright"]').text

        # <akomaNtoso>
        #   <debate name="hansard">
        #     <meta>
        #       <references source="#source">
        #         <TLCOrganization id="source" href="/ontology/organization/ca/Open%20North%20Inc." showAs="Open North Inc.">
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
        debate = Debate.new({
          name: 'hansard',
          docTitle: "Debates, #{docDate_date.strftime('%-e %B %Y')}",
          docNumber: docNumber,
          docDate: docDate_date.strftime('%A, %B %-e, %Y'),
          docDate_date: docDate_date,
          docProponent: 'Nova Scotia House of Assembly',
          legislature: "#{legislature_value.ordinalize} General Assembly",
          legislature_value: legislature_value,
          session: "#{session_value.ordinalize} Session",
          session_value: session_value,
        })
        debate.add_source(@a[:href])
        dispatch(debate)

        # Remove empty paragraphs immediately after a division heading, because
        # empty paragraphs are used as markers for the end of the division.
        # Using `starts-with` as some b tags contain non-breaking spaces.
        doc.xpath('//p[./b[starts-with(normalize-space(text()), "YEAS")]]/following-sibling::p[1]').each do |p|
          p.remove if p.text.strip.empty?
        end
        # Remove paragraphs containing only a page number and surrounding
        # empty paragraphs, in case a page number appears within a division.
        # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr02/
        # has two empty paragraphs.
        %w(HPage IPage).each do |name|
          doc.xpath("//p[./a[starts-with(@name, '#{name}')][not(node())]]/preceding-sibling::p[1]").each do |p|
            p.remove if p.text.strip.empty?
          end
          doc.xpath("//p[./a[starts-with(@name, '#{name}')][not(node())]]/following-sibling::p[position()<=2]").each do |p|
            p.remove if p.text.strip.empty?
          end
          doc.xpath("//p[./a[starts-with(@name, '#{name}')][not(node())]]").remove
        end
        doc.xpath('//p[@class="hsd_center"]').each do |p|
          p.remove if p.text.strip[/\A\d{1,4}\z/]
        end
        # Remove links and anchors appearing after a speaker's name.
        doc.css('a[title="Previous"],a[title="Next"]').remove
        doc.xpath('//a[@name][not(node())]').remove

        # Whether we have found the first speaker.
        started = false
        # The current speech.
        @speech = nil
        # Whether we are inside a narrative section.
        @narrative = false
        # Whether we are inside a division.
        @division = false

        # Generate the list of speakers, in case an unlinked name occurs
        # before its matching linked name.
        doc.css('.hsd_body p a[title="View Profile"]').each do |person_a|
          key = to_key(person_a.text)

          # The premier changes over time and will not have a stable URL.
          next if key == 'the premier'

          original_url = to_url(person_a[:href])

          response = client.head(original_url)
          case response.status
          when 200
            # If it is a present MLA with a good URL.
            url = original_url
          when 301
            # If it is a past MLA.
            if response.headers['Location'] == 'http://nslegislature.ca/index.php/people/members/'
              url = original_url
            # If it is a present MLA with a bad URL.
            else
              url = response.headers['Location']
            end
          else
            raise "Unexpected status #{response.status} for #{url}: #{@a[:href]} #{key}"
          end

          # It is conceivable to have different URLs for the same person using
          # different names. This does not seem to occur.
          # db.people.find().map(function (e) {return e.sources[0].url.toLowerCase() + ' ' + e.name}).sort()
          if @speaker_urls.key?(key)
            if @speaker_urls[key] != url
              # This is a known error. FIXME
              unless response.status == 301 && response.headers['Location'] == 'http://nslegislature.ca/index.php/people/members/' && key == 'maureen macdonald' && url == 'http://nslegislature.ca/index.php/people/members/Manning_MacDonald'
                raise "Expected #{@speaker_urls[key]} but was #{url}: #{@a[:href]} #{key}"
              end
            end
          else
            # If it is a past MLA whose URL we haven't seen yet.
            if response.status == 301 && response.headers['Location'] == 'http://nslegislature.ca/index.php/people/members/' && !@speaker_urls.has_value?(url)
              create_person(Pupa::Person.new(name: person_a.text), url)
            end
            @speaker_urls[key] = url
          end
        end

        doc.css('.hsd_body p').each_with_index do |p,index|
          person_a = p.at_css('a[title="View Profile"]')

          # Skip all text before the first speaker.
          started ||= !!person_a

          if started
            text = p.text.strip

            # A speech, which may have many paragraphs.
            if person_a
              create_speech

              person_a.remove

              from = person_a.text
              key = to_key(from)

              # The premier changes over time and will not have a stable URL.
              url = if key == 'the premier'
                to_url(person_a[:href])
              else
                @speaker_urls.fetch(key)
              end

              @speech = {
                index: index,
                element: 'speech',
                # @todo speech(by) with TLCPerson(href id showAs) in references
                from: from,
                # @todo Need to figure out what to preserve in text version.
                # @todo Need to remove leading colon: .sub(/\A:/, '') (Does speaker have square brackets when linked?)
                html: p.to_s,
                debate_id: debate._id,
              }

              @speech[:person_id] = @speaker_ids.fetch(url)

            # A speech by an unlinked person, which may have many paragraphs. FIXME
            elsif match = text[/\A(?:By|Proposé par): +([A-Z].+?) *[,(]/, 1] ||
              # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12may01/ MR. LEO GLAVINE
              text[/\A((?:HON|M[RS])\b\.? *[A-Z]+ +[A-Z'-]+)[.: ]/, 1] ||
              text[/\A(MR\. +(?:CHAIRMAN|SPEAKER)|MADAM  CHAIRMAN|SERGEANT-AT-ARMS): /, 1]
              create_speech

              # A person may be unlinked due to a middle initial or typos, for example.
              from = match.squeeze(' ').sub(/(?<=\S )[A-Z]\. (?=\S)/, '')
              key = to_key(from)

              if @speaker_urls.key?(key) || TYPOS.key?(key)
                url = @speaker_urls.fetch(key){TYPOS.fetch(key)}

                @speech = {
                  index: index,
                  element: 'speech',
                  # @todo speech(by) with TLCPerson(href id showAs) in references
                  from: match,
                  # @todo Need to figure out what to preserve in text version.
                  # @todo Need to remove leading name and colon. (Does speaker have square brackets when unlinked?)
                  html: p.to_s,
                  debate_id: debate._id,
                  fuzzy: true,
                }

                # If the first occurrence of a person's name is unlinked, that
                # person will not have been created yet.
                unless @speaker_ids.key?(url)
                  create_person(Pupa::Person.new(name: from), url)
                end

                @speech[:person_id] = @speaker_ids.fetch(url)
              else
                warn("Unrecognized speaker #{index}: #{@a[:href]} #{key}")
              end

            # A division, which will have many paragraphs.
            elsif p.at_css('b') && text[/\AYEAS[[:space:]]+NAYS\z/]
              create_speech

              @speech = {
                index: index,
                html: '',
                debate_id: debate._id,
                division: true,
              }

              # We expect a continuation.
              @division = true

            # A recorded time, which will have a single paragraph.
            elsif text[/\A\[(\d{1,2}):(\d\d) ([ap]\.\m\.)\]/]
              create_speech

              # <recordedTime time="%FT%T%:z">5:15 p.m.</recordedTime>
              dispatch(Speech.new({
                index: index,
                element: 'recordedTime',
                time: Time.zone.local(docDate_date.year, docDate_date.month, docDate_date.day, $1, $2),
                debate_id: debate._id,
              }))

            # A procedural note that has a single paragraph.
            elsif text[/\A(?:Given on \S+ \d{1,2}, +201\d|\(?Pursuant to Rule +30(?:\(1\))?\))\z/]
              create_speech

              dispatch(Speech.new({
                index: index,
                element: 'other',
                html: p.to_s, # text is centered
                text: p.text.squeeze(' ').strip,
                debate_id: debate._id,
              }))

            # A section, which will have a single paragraph. All-caps lines are
            # section headings. Must appear before narrative matching, as some
            # sections begin and end with square brackets.
            elsif text[/\A[A-Z\d,\.\(\)\[\][:space:]]+\z|\ATabled \S+ \d{1,2}, +201\d\z/] ||
              # All-bold lines may appear within a speech. Parentheses and
              # brackets may not be inside the b tags.
              @speech.nil? && p.at_css('b') && text.chomp(')') == p.css('b').text.strip.chomp(')') ||
              @speech.nil? && p.at_css('b') && text.sub(/\A\[/, '').sub(/\]\z/, '') == p.css('b').text.strip.sub(/\A\[/, '').sub(/\]\z/, '')
              create_speech

              # @todo check whether these are all debateSection(name id) and heading(id); otherwise, choose between scene, narrative or summary
              dispatch(Speech.new({
                index: index,
                element: 'debateSection',
                html: p.to_s,
                # @todo Need to figure out what to preserve in text version.
                debate_id: debate._id,
              }))

            # A narrative that has a single paragraph.
            elsif text[/\A\[/] && text[/\]\z/]
              create_speech

              # Find all one-paragraph narratives. (535)
              # db.speeches.find({html: new RegExp('> *\\[[^<]*\\]')}).map(function(e){return e.html}).sort()
              # Find any one-paragraph narratives with tags. (41)
              # db.speeches.find({$or: [{html: new RegExp('> *\\[[^<]*<[^\/]')}, {html: new RegExp('>[^<]*<[^\/][^>]*> *\\[')}]}).map(function(e){return e.html}).sort()
              dispatch(Speech.new({
                index: index,
                element: 'narrative',
                html: p.to_s, # no classes or tags
                text: p.text.squeeze(' ').strip.sub(/\A\[/, '').sub(/\]\z/, ''),
                debate_id: debate._id,
              }))

            # A narrative that has many paragraphs.
            elsif text[/\A\[/]
              create_speech

              # Find all multi-paragraph narratives. (12)
              # db.speeches.find({html: new RegExp('> *\\[.*<p>')}).map(function(e){return e.html}).sort()
              @speech = {
                index: index,
                element: 'narrative',
                html: p.to_s, # no classes or tags
                text: p.to_s.squeeze(' ').gsub(/(?<=<p>) /, '').gsub(/(?<=<\/p>)(?=.)/, "\n"),
                debate_id: debate._id,
              }

              # We expect a continuation.
              @narrative = true

            # Assumed to be a continuation. # @todo Check if this assumption holds.
            elsif !text.empty?
              if @speech
                # @todo transform this HTML appropriately.
                @speech[:html] += p.to_s
              elsif text[/\AThe +honourable +(?:member |[A-Z]).+\./]
                # Unattributed speeches by the Speaker.
                # db.speeches.find({from: null, html: /> *The +honourable/}).map(function(e){return e.html}).sort()
                dispatch(Speech.new({
                  index: index,
                  element: 'speech',
                  html: p.to_s, # no classes or tags
                  text: p.text.squeeze(' ').strip,
                  debate_id: debate._id,
                  person_id: @speaker_ids.fetch('http://nslegislature.ca/index.php/people/speaker'),
                }))
              elsif !text[/\A\d+\z/] # unlinked page number
                warn("Unclassified paragraph #{index}: #{@a[:href]}: #{p.to_s.inspect}")
              end

              if text[/\]\z/]
                if @narrative
                  @narrative = false
                  create_speech
                else
                  warn("Unmatched ] #{index}: #{@a[:href]}: #{p.to_s.inspect}")
                end
              end
            # An empty paragraph follows the end of a division. We don't want a
            # division collecting more than necessary.
            elsif @division
              create_speech
            end
          end
        end

        # Create the last speech.
        if @speech
          create_speech
        end
      end

      list_a = list.at_xpath('//a[text()=">"]')
    end while list_a
  end

private

  def create_speech
    @division = false
    if @narrative
      warn("Unclosed narrative #{@a[:href]}:\n#{JSON.pretty_generate(@speech)}")
      @narrative = false
    end
    if @speech
      dispatch(Speech.new(@speech))
      @speech = nil
    end
  end

  def to_key(string)
    # Mr. and Ms. can disambiguate Maureen MacDonald from Manning MacDonald.
    string.sub(/\A(?:#{string[/\bMacDonald\b/i] ? /Hon/i : /(?:Hon|Mr|Ms)/i}\b\.?|Honourable\b|Madam\b)/i, '').squeeze(' ').strip.downcase
  end

  def to_url(path)
    # Normalize all URLs to exclude the "/en/" part of the path.
    "http://nslegislature.ca#{path.sub('/en/', '/')}"
  end
end
