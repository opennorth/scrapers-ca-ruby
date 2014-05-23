require 'active_support/core_ext/integer/inflections'

# @todo Find good documentation for URIs (use lowerCamelCase for committee, use ca-ns instead of country code)
# @see https://code.google.com/p/akomantoso/wiki/Using_Akoma_Ntoso_URIs#TLC_Organization
# @see http://www.akomantoso.org/release-notes/akoma-ntoso-3.0-schema/naming-conventions-1/bungenihelpcenterreferencemanualpage.2008-01-09.1484954524
# @todo Ask about https://github.com/mysociety/za-hansard/tree/master/za_hansard/importers
class NovaScotia
  # Names are not linked if there are errors in the given name or family name,
  # if the honorary prefix is missing, unabbreviated or missing a period, or if
  # the name is of a role.
  TYPOS = {
    # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14may01/ given name
    'pan eyking' => 'http://nslegislature.ca/index.php/en/people/members/pam_eyking',
    # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14apr28/ given name, family name
    'michael samson' => 'http://nslegislature.ca/index.php/en/people/members/michel_p_samson1',
    'stephen macneil' => 'http://nslegislature.ca/index.php/en/people/members/Stephen_McNeil',
    # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14apr16/ family name
    'sterling bellieau' => 'http://nslegislature.ca/index.php/en/people/members/Sterling_Belliveau',
    # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14mar31/ given name
    'gordon gosse' => 'http://nslegislature.ca/index.php/en/people/members/gordie_gosse1',
    # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_13dec11/ given name
    'diane whalen' => 'http://nslegislature.ca/index.php/en/people/members/diana_whalen1',
    # http://nslegislature.ca/index.php/proceedings/hansard/C90/house_13may09/
    'michele raymond' => 'http://nslegislature.ca/index.php/en/people/members/Michele_Raymond',
    # http://nslegislature.ca/index.php/proceedings/hansard/C90/house_13may08/ given name
    'mailyn more' => 'http://nslegislature.ca/index.php/en/people/members/Marilyn_More',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12nov27/ given name
    'sterlng belliveau' => 'http://nslegislature.ca/index.php/en/people/members/Sterling_Belliveau',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12nov07/ family name
    'bellieveau' => 'http://nslegislature.ca/index.php/en/people/members/Sterling_Belliveau',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12nov08/ given name
    'jaimie baillie' => 'http://nslegislature.ca/index.php/en/people/members/jamie_baillie',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12oct31/ given name
    'bekcy kent' => 'http://nslegislature.ca/index.php/en/people/members/Becky_Kent',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12oct25/ family name
    "d'entremount" => 'http://nslegislature.ca/index.php/en/people/members/Christopher_A_dEntremont',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12may10/ given name
    'mariyln more' => 'http://nslegislature.ca/index.php/en/people/members/Marilyn_More',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr17/ family name
    'peterson-rayfuse' => 'http://nslegislature.ca/index.php/en/people/members/Denise_Peterson-Rafuse',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr10/ family name
    'macneil' => 'http://nslegislature.ca/index.php/en/people/members/Stephen_McNeil',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr04/ family name
    "d'enteremont" => 'http://nslegislature.ca/index.php/en/people/members/Christopher_A_dEntremont',
    # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_12mar29/ role-based
    'sergeant-at-arms' => 'http://nslegislature.ca/sergeant-at-arms',
    # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec06/ given name, role-based
    'vickie conrad' => 'http://nslegislature.ca/index.php/en/people/members/Vicki_Conrad',
    'chairman' => 'http://nslegislature.ca/chairman',
    # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12dec04/ family name
    'ross laundry' => 'http://nslegislature.ca/index.php/en/people/members/Ross_Landry',
    # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec02/ family name
    'harold therault' => 'http://nslegislature.ca/index.php/en/people/members/Harold_Theriault',
    # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov25/ family name
    "christopher d'entromont" => 'http://nslegislature.ca/index.php/en/people/members/Christopher_A_dEntremont',
    # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov23/ family name, family name
    'sterling bellieveau' => 'http://nslegislature.ca/index.php/en/people/members/Sterling_Belliveau',
    'maureen macdonld' => 'http://nslegislature.ca/index.php/en/people/members/Maureen_MacDonald',
    # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov01/ both names
    'william estabooks' => 'http://nslegislature.ca/index.php/en/people/members/Bill_Estabrooks',
  }

  def scrape_speeches
    Time.zone = 'Atlantic Time (Canada)'

    # A map between speaker names and URLs.
    @speakers = {}

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
        doc.xpath('//p[./a[starts-with(@name, "HPage")][not(node())]]/preceding-sibling::p[1]').each do |p|
          p.remove if p.text.strip.empty?
        end
        doc.xpath('//p[./a[starts-with(@name, "HPage")][not(node())]]/following-sibling::p[position()<=2]').each do |p|
          p.remove if p.text.strip.empty?
        end
        doc.xpath('//p[@class="hsd_center"]').each do |p|
          p.remove if p.text.strip[/\A\d{1,4}\z/]
        end
        doc.xpath('//p[./a[starts-with(@name, "HPage")][not(node())]]').remove
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
          @speakers[to_key(person_a.text)] = "http://nslegislature.ca#{person_a[:href]}"
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

              @speech = {
                index: index,
                # @todo speech(by) with TLCPerson(href id showAs) in references
                from: person_a.text,
                # @todo Need to figure out what to preserve in text version.
                # @todo Need to remove leading colon: .sub(/\A:/, '')
                html: p.to_s.strip,
                person: {'links.url' => "http://nslegislature.ca#{person_a[:href]}"},
                debate_id: debate._id,
              }

              # We don't know if there is a continuation.

            # A speech by an unlinked person, which may have many paragraphs. FIXME
            elsif match = text[/\A(?:By|Proposé par): +([A-Z].+?) *[,(]/, 1] ||
              # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12may01/ MR. LEO GLAVINE
              text[/\A((?:HON|M[RS])\b\.? *[A-Z]+ +[A-Z'-]+)[.: ]/, 1] ||
              text[/\A(MR\. +(?:CHAIRMAN|SPEAKER)|MADAM  CHAIRMAN|SERGEANT-AT-ARMS): /, 1]
              create_speech

              # A person may be unlinked due to a middle initial or typos, for example.
              from = match.squeeze(' ').sub(/(?<=\S )[A-Z]\. (?=\S)/, '')
              key = to_key(from)

              if @speakers.key?(key) || TYPOS.key?(key)
                @speech = {
                  index: index,
                  # @todo speech(by) with TLCPerson(href id showAs) in references
                  from: match,
                  # @todo Need to figure out what to preserve in text version.
                  # @todo Need to remove leading name and colon.
                  html: p.to_s.strip,
                  person: {'links.url' => @speakers.fetch(key){TYPOS.fetch(key)}},
                  debate_id: debate._id,
                }
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
                time: Time.zone.local(docDate_date.year, docDate_date.month, docDate_date.day, $1, $2),
                debate_id: debate._id,
              }))

            # A procedural note that has a single paragraph.
            elsif text[/\A(?:Given on \S+ \d{1,2}, +201\d|\(?Pursuant to Rule +30(?:\(1\))?\))\z/]
              create_speech

              # <other>...</other>
              dispatch(Speech.new({
                index: index,
                # @todo Need to figure out what to preserve in text version.
                html: p.to_s.strip,
                debate_id: debate._id,
              }))

            # A narrative that has a single paragraph.
            elsif text[/\A\[/] && text[/\]\z/]
              create_speech

              # <narrative>...</narrative>
              dispatch(Speech.new({
                index: index,
                # @todo Need to figure out what to preserve in text version.
                html: p.to_s.strip,
                debate_id: debate._id,
              }))

            # A narrative that has many paragraphs.
            elsif text[/\A\[/]
              create_speech

              @speech = {
                index: index,
                # @todo Need to figure out what to preserve in text version.
                html: p.to_s.strip,
                debate_id: debate._id,
              }

              # We expect a continuation.
              @narrative = true

            # A section, which will have a single paragraph. All-caps lines are
            # sectio headings.
            elsif text[/\A[A-Z\d,\.\(\)\[\][:space:]]+\z|\ATabled \S+ \d{1,2}, +201\d\z/] ||
              # All-bold lines may appear within a speech. The closing b tag may
              # occur inside the closing parenthesis. FIXME
              @speech.nil? && p.at_css('b') && text.chomp(')') == p.at_css('b').text.strip.chomp(')')
              create_speech

              # @todo check whether these are all debateSection(name id) and heading(id); otherwise, choose between scene, narrative or summary
              dispatch(Speech.new({
                index: index,
                # @todo Need to figure out what to preserve in text version.
                html: p.to_s.strip,
                debate_id: debate._id,
              }))

            # Assumed to be a continuation. # @todo Check if this assumption holds.
            elsif !text.empty?
              if @speech
                @speech[:html] += p.to_s.strip
              elsif text[/\AThe +honourable +(?:member |[A-Z]).+\./]
                dispatch(Speech.new({
                  index: index,
                  # @todo Need to figure out what to preserve in text version.
                  html: p.to_s.strip,
                  debate_id: debate._id,
                }))
              elsif !text[/\A\d+\z/] # unlinked page number
                warn("Unclassified paragraph #{index}: #{@a[:href]}: #{p.to_s.strip.inspect}")
              end

              if text[/\]\z/]
                if @narrative
                  @narrative = false
                  create_speech
                else
                  warn("Unmatched ] #{index}: #{@a[:href]}: #{p.to_s.strip.inspect}")
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
    string.sub(/\A(?:Hon|Mr|Ms)\b\.?|\A(?:Honourable|Madam)\b/i, '').squeeze(' ').strip.downcase
  end
end
