class NovaScotia
  def scrape_speeches
    Time.zone = 'Atlantic Time (Canada)'

    # @note Can extract the majority party, the assembly dates, and the session dates.
    doc = get('http://nslegislature.ca/index.php/proceedings/hansard/')
    doc.css('.latest .assembly a').each do |a|
      paginate(a)
    end

    # Ignore hansards where names are not linked.
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

      list.xpath('//tr[position()>1]').reject do |tr|
        # Ignore rows with colspans and hansards where names are not linked.
        # @note 2011-11-02 "John MacDonnell" is unlinked. Only 2011-11-01 and
        #   2011-10-31 have links earlier than this date.
        # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov02/
        tr.at_css('td').text == ' ' || Date.parse(tr.at_css('a[href]')) <= Date.new(2011, 11, 2) # non-breaking space
      end.each do |tr|
        @a = tr.at_css('a[href]') # XXX
        docDate_date = Date.parse(@a.text)

        # @note Can extract the speaker, the publisher, the printer, the table
        #   of contents, the start time, the deputy speaker.
        doc = get(@a[:href])

        # The sitting on the list page can be incorrect. FIXME
        # @see http://nslegislature.ca/index.php/en/proceedings/session_hansards/C94/
        docNumber = doc.at_xpath('//p[@class="hansard_title"]/span[@class="alignright"]').text
        # The sitting on the hansard page can be incorrect. FIXME
        # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov03/
        docNumber = "1#{docNumber}" if docNumber[/\A\d-\d\d\z/]

        debate = Debate.new({
          name: 'hansard',
          docTitle: "Debates, #{docDate_date.strftime('%-e %B %Y')}",
          docNumber: docNumber,
          docDate_date: docDate_date,
          docDate: docDate_date.strftime('%A, %B %-e, %Y'),
          docProponent: 'Nova Scotia House of Assembly',
          legislature_value: legislature_value,
          legislature: "#{legislature_value.ordinalize} General Assembly",
          session_value: session_value,
          session: "#{session_value.ordinalize} Session",
        })
        debate.add_source(@a[:href])
        dispatch(debate)

        create_speakers(doc)
        clean_document(doc)

        # Initialize the state machine.
        @state = @initial_state
        # The current speech.
        @speech = nil
        # Whether "NOTICES OF MOTION UNDER RULE 32(3)" has been seen.
        rule_32 = false
        # The person being asked a question.
        answer_from = nil
        answer_from_id = nil

        # Parse the hansard.
        doc.xpath('//div[@class="hsd_body"]/*').each_with_index do |p,index|
          text = p.text.gsub(/[[:space:]]+/, ' ').strip.sub(/\A�/, '').gsub('&amp;', '&')

          unless %w(blockquote p ul table).include?(p.node_name)
            if text.empty?
              next
            else
              raise "Unexpected node #{p.to_s.inspect} | #{@a[:href]}"
            end
          end

          # Mr. Premier is linked within a blockquote.
          # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec09/
          person_a = p.node_name == 'p' && p.at_css('a[title="View Profile"]')

          # Skip all text before the first speaker.
          if initial_state?
            if person_a
              transition_to(:speech_begin)
            else
              next
            end
          end

          # This debate contains a lot of cruft in the footer.
          break if @a[:href] == 'http://nslegislature.ca/index.php/proceedings/hansard/C94/house_13dec12/' && p.to_s.strip == '<p class="hsd_center"><b>Province of Nova Scotia</b></p>'

          # An empty paragraph follows the end of a division. We don't want a
          # division collecting more than necessary. If an empty paragraph
          # appears within a division, warnings will be issued for the rest
          # of the division.
          if text.empty?
            if @state == :division
              create_speech
              transition_to(:speech_begin)
            end

          # A division.
          elsif p.node_name == 'table'
            if text['YEAS']
              transition_to(:division)
              create_speech

              @speech = {
                index: index,
                html: p.to_s,
                note: 'division',
                debate_id: debate._id,
              }

              transition_to(:division_continue)
            else
              transition_to(:division_continue)
              @speech[:html] += "\n#{p.to_s}"
            end

          # A question.
          elsif [:question_line1, :question_line2].include?(@state)
            person = person_a && person_a.text.strip.squeeze(' ') || text.match(/\A(?:BY|By|TO|To): ([A-Z].+?)(?:,| \(|\z)/)[1]
            key = to_key(person.sub(/(?<=\S )[A-Z]\. (?=\S)/, ''))

            # In the same hansard, The Premier is asked a question.
            # @see http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12may17/
            if person != 'Deputy Premier and Minister responsible for Communications Nova Scotia'
              url = @speaker_urls.fetch(key){TYPOS.fetch(key)}
            end

            if @state == :question_line1
              @speech = {
                index: index,
                element: 'question',
                debate_id: debate._id,
              }
            end

            field = text[/\A(?:BY|By): /] ? :from : :to

            @speech[field] = person
            if ROLES.include?(key)
              @speech["#{field}_as".to_sym] = key
            elsif url
              @speech["#{field}_id".to_sym] = @speaker_ids.fetch(url)
            end

            if @state == :question_line1
              transition_to(:question_line2)
            else # :question_line2
              transition_to(:question)
            end

          # A resolution.
          elsif @state == :resolution_by
            from = person_a && person_a.text.strip.squeeze(' ') || text[/\A(?:By|Proposé par): ([A-Z].+?) ?[,(]/, 1]

            @speech = {
              index: index,
              element: 'speech',
              note: 'resolution',
              debate_id: debate._id,
            }

            if from
              key = to_key(from.sub(/(?<=\S )[A-Z]\. (?=\S)/, ''))

              @speech[:from] = from
              if ROLES.include?(key)
                @speech[:from_as] = key
              else
                @speech[:from_id] = @speaker_ids.fetch(@speaker_urls.fetch(key){TYPOS.fetch(key)})
              end
            # Explicit exceptions are made for unattributed resolutions.
            elsif @a[:href] != 'http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14apr02/'
              error("Speaker not found #{text} | #{index} #{@a[:href]}")
            end

            transition_to(:resolution)

          # Question text.
          elsif @state == :question
            @speech.merge!({
              html: p.to_s,
              text: clean_paragraph(p),
            })
            transition_to(:question_continue)

          # Resolution text.
          elsif @state == :resolution
            @speech.merge!({
              html: p.to_s,
              text: clean_paragraph(p),
            })
            transition_to(:resolution_continue)

          # An answer.
          elsif @state == :answer
            unless p.at_css('i')
              error("Expected i tag in answer #{p.to_s.inspect} | #{index} #{a[:href]}")
            end

            @speech = {
              index: index,
              element: 'answer',
              html: p.to_s,
              text: clean_paragraph(p),
              debate_id: debate._id,
            }

            if answer_from && answer_from_id
              @speech.merge!({
                from: answer_from,
                from_id: answer_from_id,
              })
              answer_from = nil
              answer_from_id = nil
            end

            transition_to(:answer_continue)

          elsif @state == :answer_continue && p.at_css('i')
            if person_a
              to = person_a.text.strip.squeeze(' ')
              key = to_key(to.sub(/(?<=\S )[A-Z]\. (?=\S)/, ''))

              @speech[:to] = to
              if ROLES.include?(key)
                @speech[:to_as] = key
              else
                @speech[:to_id] = @speaker_ids.fetch(@speaker_urls.fetch(key){TYPOS.fetch(key)})
              end
            end

            @speech[:html] += "\n#{p.to_s}"
            @speech[:text] += "\n#{clean_paragraph(p)}"

          # A speech, which may have many paragraphs.
          elsif person_a
            transition_to(:speech)
            create_speech

            from = person_a.text.strip.squeeze(' ')
            key = to_key(from)

            # The premier changes over time and will not have a stable URL.
            url = if key == 'premier'
              to_url(person_a[:href])
            else
              @speaker_urls.fetch(key)
            end

            # Remove the name from the text of the speech.
            person_a.remove

            @speech = {
              index: index,
              element: 'speech',
              from: from,
              html: p.to_s,
              text: clean_paragraph(p).sub(/\A:\s*/, ''),
              debate_id: debate._id,
            }

            if ROLES.include?(key)
              @speech[:from_as] = key
            else
              @speech[:from_id] = @speaker_ids.fetch(url)
            end

            if text[/\b(?:[Ww]ill|[WwCc]ould) (?:you )?please call (?:Bill|Resolution)\b/]
              # This text is always followed by a heading.
              transition_to(:heading_begin)
              create_speech
            else
              transition_to(:speech_continue)
            end

          # A speech by an unlinked person, which may have many paragraphs.
          # No space after honorific prefix: HON.JAMIE  BAILLIE:
          # No period after abbreviation: MR DAVID WILSON:
          # Family name with apostrophe: Hon. Christopher d'Entremont
          # Family name with hyphen: MS. PETERSON-RAFUSE
          # Period after name: MR. KEITH BAIN.
          # Space after name: MR. LEO GLAVINE
          # Role-based speeches.
          elsif match = text.match(/\A((?:HON|M[RS])\b\.? ?[A-Z]+ [A-Z'-]+)[.:; ]|\A(MR\. (?:CHAIRMAN|SPEAKER)|MADAM CHAIRMAN|SERGEANT-AT-ARMS|THE (?:ADMINISTRATOR|LIEUTENANT GOVERNOR)):/)
            transition_to(:speech)
            create_speech

            # A person may be unlinked due to a middle initial.
            from = match[1] || match[2]
            key = to_key(from.sub(/(?<=\S )[A-Z]\. (?=\S)/, ''))

            @speech = {
              index: index,
              element: 'speech',
              from: from,
              html: p.to_s,
              text: clean_paragraph(p).sub(/\A#{Regexp.escape(match[0])}[.:;]?\s*/, ''),
              fuzzy: true,
              debate_id: debate._id,
            }

            if @speaker_urls.key?(key) || TYPOS.key?(key)
              url = @speaker_urls.fetch(key){TYPOS.fetch(key)}

              if ROLES.include?(key)
                @speech[:from_as] = key
              else
                # If the first occurrence of a person's name is unlinked, that person will not have been created yet.
                unless @speaker_ids.key?(url)
                  create_person(Pupa::Person.new(name: from), url)
                end
                @speech[:from_id] = @speaker_ids.fetch(url)
              end
            else
              error("Unrecognized speaker #{key} | #{index} #{@a[:href]}")
            end

            transition_to(:speech_continue)

          # A short, anonymous speech.
          elsif from = text[/\A(AN(?:OTHER)? HON\. MEMBER): /, 1]
            transition_to(:speech)
            create_speech

            dispatch(Speech.new({
              index: index,
              element: 'speech',
              from: from,
              html: p.to_s,
              text: clean_paragraph(p.inner_html).sub(/\AAN(?:OTHER)? HON\. MEMBER: /, ''),
              debate_id: debate._id,
            }))

          # A division, which will have many paragraphs.
          elsif p.at_css('b') && text[/\AYEAS[[:space:]]+NAYS\z/]
            transition_to(:division)
            create_speech

            @speech = {
              index: index,
              html: '',
              text: '',
              note: 'division',
              debate_id: debate._id,
            }

            # We expect a continuation.
            transition_to(:division_continue)

          # A recorded time, which will have a single paragraph.
          elsif text[/\A\[(\d{1,2}):(\d\d) ([ap]\.\m\.)\]/]
            transition_to(:recorded_time)
            create_speech

            dispatch(Speech.new({
              index: index,
              element: 'recordedTime',
              time: Time.zone.local(docDate_date.year, docDate_date.month, docDate_date.day, $1, $2),
              html: p.to_s,
              text: clean_paragraph(p.inner_html).sub('[', '').sub(']', ''),
              debate_id: debate._id,
            }))

          # A heading, which will have a single paragraph.
          # @note This block must run before the narrative block, as some
          #   headings begin and end with square brackets.
          elsif (
            # Avoids capturing "<p>.</p>".
            # Allow some lowercase letters, e.g. "CBC  - ANNIV. (75th)" and "PREM.: DHAs -  AMALGAMATION/SAVINGS".
            text[/\A[A-ZÉths\d"&'(),.:\/\[\][:space:]–-]{2,}\z|\A(?:Tabled|Given on) \S+ \d{1,2}, 20\d\d\z|\A\(?Pursuant to Rule 30(?:\(1\))?\)?\z/] &&
            # Ignore non-heading paragraphs.
            !["SPEAKER'S RULING:", "THEREFORE BE IT RESOLVED AS FOLLOWS:"].include?(text) ||
            # All-bold lines may appear within a speech. Parentheses and brackets may not be inside the b tags.
            # @todo This is causing headings to be captured by speeches...
            @speech.nil? && p.at_css('b') && text.chomp(')') == p.css('b').text.strip.squeeze(' ').chomp(')') ||
            @speech.nil? && p.at_css('b') && text.gsub(/[\[\]]/, '') == p.css('b').text.strip.squeeze(' ').gsub(/[\[\]]/, '')
          )
            text = clean_heading(text) # @todo check this method

            # The person answering a question is hard to parse.
            if text == 'RESPONSE:' && @state == :question_continue
              answer_from = @speech[:to]
              answer_from_id = @speech[:to_id]
            end

            transition_to(:heading)
            create_speech

            # There are hundreds of possible prefixes and suffixes for issue-
            # based headings, so check the format. Avoid matching on colons,
            # because colons may indicate speakers.
            unless HEADINGS.include?(text) || HEADINGS_RE.any?{|pattern| text[pattern]} || text[/\A- | [&-] /] || text[/[\.)]:/]
              warn("Unrecognized heading #{text} | #{index} #{@a[:href]}")
            end

            dispatch(Speech.new({
              index: index,
              element: 'heading',
              num_title: text[/\A(?:RESOLUTION|QUESTION|) NO\. (\d+)\z/, 1],
              html: p.to_s,
              text: text,
              debate_id: debate._id,
            }))

            if text == 'NOTICES OF MOTION UNDER RULE 32(3)'
              rule_32 = true
            elsif rule_32 && text[/\ARESOLUTION NO\. \d+\z/]
              transition_to(:resolution_by)
            elsif text[/\AQUESTION NO\. \d+\z/]
              transition_to(:question_line1)
            elsif text == 'RESPONSE:'
              transition_to(:answer)
            end

          # A narrative that has a single paragraph.
          elsif text[/\A\[/] && text[/\]\z/]
            transition_to(:narrative)
            create_speech

            dispatch(Speech.new({
              index: index,
              element: 'narrative',
              html: p.to_s,
              text: clean_paragraph(p.inner_html).sub('[', '').sub(']', ''),
              debate_id: debate._id,
            }))

          # A narrative that has many paragraphs.
          elsif text[/\A\[/]
            transition_to(:narrative)
            create_speech

            @speech = {
              index: index,
              element: 'narrative',
              html: p.to_s,
              text: clean_paragraph(p).sub('[', ''),
              debate_id: debate._id,
            }

            # We expect a continuation.
            transition_to(:narrative_continue)

          else
            # A continuation.
            if @speech
              if @state.to_s[/_continue\z/]
                transition_to(@state)
              else
                error("Illegal transition from #{@state} to a continuation")
              end

              @speech[:html] += "\n#{p.to_s}"
              @speech[:text] += "\n#{clean_paragraph(p)}"
              if @state == :narrative_continue
                @speech[:text].sub!(']', '')
              end

            # An unattributed speech by the speaker.
            elsif text[/\AThe honourable (?:member |[A-Z]).+\.\]?\z/] || text[/\ASPEAKER'S RULING: /]
              transition_to(:speech)

              dispatch(Speech.new({
                index: index,
                element: 'speech',
                from_as: 'speaker',
                html: p.to_s,
                text: clean_paragraph(p.inner_html),
                debate_id: debate._id,
              }))

            # An unknown paragraph.
            elsif !text[/\A\d+\z/] # unlinked page numbers
              warn("Unsaved paragraph #{p.to_s.inspect} #{text} | #{index} #{@a[:href]}")
            end

            if text[/\]\z/]
              if @previous_state == :narrative_continue
                transition_to(:speech_begin)
                create_speech
              else
                warn("Unmatched ] #{p.to_s.inspect} | #{index} #{@a[:href]}")
              end
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
    if @state == :narrative_continue
      warn("Unclosed narrative #{@a[:href]}\n#{JSON.pretty_generate(@speech)}")
    end
    if @speech
      dispatch(Speech.new(@speech))
    end
    @speech = nil
  end

  def to_key(string)
    # Mr. and Ms. can disambiguate Maureen MacDonald from Manning MacDonald.
    string.sub(/\A(?:#{string[/\bMacDonald\b/i] ? /Hon/i : /(?:Hon|Mr|Ms|The)/i}\b\.?|Honourable\b|Madam\b)/i, '').strip.squeeze(' ').downcase
  end

  def to_url(path)
    # Normalize all URLs to exclude the "/en/" part of the path.
    "http://nslegislature.ca#{path.sub('/en/', '/')}"
  end

  def clean_heading(string)
    # Only replace parentheses if they occur at both the start and the end, to
    # avoid breaking "MOTION UNDER RULE 5(5)".
    string = string.gsub(/[\[\]]/, '').sub(/\A\((.+)\)\z/, '\1')

    HEADING_TYPOS.each do |incorrect,correct|
      case incorrect
      when String
        if string == incorrect
          return correct
        end
      when Regexp
        if string[incorrect]
          return string.sub(incorrect, correct)
        end
      end
    end

    string
  end

  def clean_paragraph(p)
    # Text may contain <a>, <br>, <i>, <li>, <sup>, <u>, <ul> tags.
    p.to_s.strip.squeeze(' ').
      # Use proper characters.
      gsub('. . .', '…').
      gsub('...', '…').
      gsub('&amp;', '&').
      # Remove formatting.
      sub(' class="hsd_general"', '').
      sub(' style="font-size: .7em"', '').
      # Remove leading and trailing whitespace inside paragraphs.
      sub(/(<p>(?:<[^>]+>)*)\s+/, '\1').
      sub(/\s+((?:<\/[^>]+>)*<\/p>)/, '\1').
      # Remove leading and trailing <br> tags inside paragraphs.
      sub(/(<p>(?:<[^>]+>)*?)(?:<br>\s*)+/, '\1').
      sub(/(?:\s*<br>)+((?:<\/[^>]+>)*<\/p>)/, '\1').
      # Remove spaces between list items.
      gsub(/<\/li>\s+<li>/, "</li>\n<li>").
      # Replace double <br> with paragraphs.
      # gsub('\s*<br>\s*<br>\s*', "</p>\n<p>"). # @todo
      # Remove single <br>, which always appears to be accidental.
      # gsub('\s*<br>\s*', ' '). # @todo
      # Remove linked names from answers to questions. One resolution has a hyperlink to an external website.
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec15/
      gsub(%r{<a href="/index.php/en/people/members/\S+" class="hsd_mla" title="View Profile">([^<]+)</a>}, '\1').
      gsub(%r{<a href="/index.php/people/speaker" title="View Profile">([^<]+)</a>}, '\1').
      gsub(%r{<a name="\w+">([^<]+)</a>}, '\1')
  end

  def clean_document(doc)
    # Replace <em> tags with <i> tags.
    doc.xpath('//em').each do |e|
      e.name = 'i'
    end
    # Replace <strong> tags with <b> tags.
    doc.xpath('//strong').each do |e|
      e.name = 'b'
    end

    # Remove nested identical inline tags.
    doc.xpath('//b/b').each do |e|
      e.replace(doc.create_text_node(e.text))
    end
    # Merge consecutive identical inline tags.
    doc.xpath('//b/following-sibling::b').each do |e|
      e.previous.inner_html += e.text
      e.remove
    end

    # Remove empty <b> and <i> tags (which may nonetheless break up words).
    doc.xpath('//b[not(normalize-space(text()))]|//i[not(normalize-space(text()))]').each do |e|
      e.replace(doc.create_text_node(e.text))
    end
    # Remove accidental <sup> tags.
    doc.xpath('//sup[string-length(normalize-space(text()))=1]').each do |e|
      e.replace(doc.create_text_node(e.text))
    end
    # Remove accidental <b> tags.
    doc.xpath('//b[string-length(normalize-space(text()))=1]').each do |e|
      e.replace(doc.create_text_node(e.text))
    end

    # Remove script tags (for encoding email addresses).
    doc.xpath('//script').remove
    # Replace hidden email addresses.
    doc.xpath('//span[contains(@id, "eeEncEmail_")]').each do |span|
      span.replace(doc.create_text_node('(hidden)'))
    end

    # Remove empty paragraphs immediately after a division heading, because
    # empty paragraphs are used as markers for the end of the division.
    # Using `starts-with` as some <b> tags contain non-breaking spaces.
    doc.xpath('//p[./b[starts-with(normalize-space(text()), "YEAS")]]/following-sibling::p[1]').each do |p|
      p.remove if p.text.strip.empty?
    end

    # Remove paragraphs containing only a page number. Remove surrounding
    # empty paragraphs, in case a page number appears within a division.
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr02/
    # has two empty paragraphs.
    doc.xpath('//p[./a[starts-with(@name, "HPage")][not(node())]]/preceding-sibling::p[1]').each do |p|
      p.remove if p.text.strip.empty?
    end
    doc.xpath('//p[./a[starts-with(@name, "HPage")][not(node())]]/following-sibling::p[position()<=2]').each do |p|
      p.remove if p.text.strip.empty?
    end
    doc.xpath('//p[./a[starts-with(@name, "HPage")][not(node())]]').each do |p|
      p.remove if p.text.strip[/\[Page \d{1,4}\]/]
    end
    # A few have no <a> tag with a name attribute preceding the link.
    doc.xpath('//p[./a[starts-with(@href, "#IPage")]]').remove
    doc.xpath('//p[./a[starts-with(@href, "#pagetop")]]').remove
    doc.xpath('//p[@class="hsd_center"]').each do |p|
      p.remove if p.text.strip[/\A\d{1,4}\z/]
    end

    # Remove links and anchors appearing after a speaker's name.
    doc.css('a[title="Previous"],a[title="Next"]').remove
    doc.xpath('//a[@name][not(node())]').remove
  end

  def create_speakers(doc)
    # Add role-based speakers.
    # @todo [post-scrape] Check for differences in trailing slashes.
    @speaker_urls.merge!({
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C90/house_13may10/
      'administrator' => 'http://en.wikipedia.org/wiki/Nova_Scotia_Court_of_Appeal',
      'chairman' => 'http://nslegislature.ca/index.php/people/deputy-speaker/',
      'clerk' => 'http://nslegislature.ca/index.php/people/offices/clerk',
      'lieutenant governor' => 'http://nslegislature.ca/index.php/people/lt-gov/',
      'sergeant-at-arms' => 'http://nslegislature.ca/index.php/people/offices/sergeant-at-arms',
      'speaker' => 'http://nslegislature.ca/index.php/people/speaker',
      'premier' => 'http://premier.novascotia.ca/',
    })

    # Generate the list of speakers, in case an unlinked name occurs before
    # its matching linked name.
    doc.css('.hsd_body p a[title="View Profile"]').each do |person_a|
      key = to_key(person_a.text)

      # The premier changes over time and will not have a stable URL.
      next if key == 'premier'

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
        raise "Unexpected status #{response.status} for #{url} | #{@a[:href]} #{key}"
      end

      # It is also conceivable to have different URLs for the same person
      # using different names. This does not seem to occur:
      # db.people.find().map(function (e) {return e.sources[0].url.toLowerCase() + ' ' + e.name}).sort()
      if @speaker_urls.key?(key)
        if @speaker_urls[key] != url
          unless response.status == 301 && response.headers['Location'] == 'http://nslegislature.ca/index.php/people/members/' &&
            # FIXME 2014-05-23 publications@gov.ns.ca
            key == 'maureen macdonald' && url == 'http://nslegislature.ca/index.php/people/members/Manning_MacDonald'
            raise "Expected #{@speaker_urls[key]} but was #{url} | #{@a[:href]} #{key}"
          end
        end
      else
        # If it is a past MLA whose URL we haven't seen yet.
        if response.status == 301 && response.headers['Location'] == 'http://nslegislature.ca/index.php/people/members/' && !@speaker_urls.has_value?(url)
          create_person(Pupa::Person.new(name: person_a.text.strip.squeeze(' ')), url)
        end
        @speaker_urls[key] = url
      end
    end
  end
end
