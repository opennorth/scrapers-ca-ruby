require File.expand_path(File.join('..', 'utils.rb'), __dir__)

class NovaScotia < GovernmentProcessor
  def initialize(*args)
    super

    @initial_state = :not_started
    @previous_state = nil

    # If the machine is in a state ending in "_begin", the next state is
    # expected to be that state.
    @transitions = {
      not_started: [:speech_begin],

      speech_begin: [:speech],
      speech: [
        # Multi-line speech
        :speech_continue,
        # Predicted heading
        :heading_begin,
        # One-line speech
        :heading,
        :speech,
      ],
      speech_by: [:speech_continue],
      speech_continue: [
        :speech_continue,
        :division,
        :heading,
        :other, # A speaker may interject between "INTRODUCTION OF BILLS"
        :narrative,
        :recorded_time,
        :speech,
      ],

      division: [:division_continue],
      division_continue: [
        :division_continue,
        :speech,
      ],

      recorded_time: [
        :division,
        :narrative,
        :speech,
      ],

      # In three cases, there is an interruption after "would you please call..."
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12may14/
      # @see http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec15/
      heading_begin: [:heading],
      heading: [
        # Predicted
        :other_begin,
        :subheading_begin,
        # Answer
        :answer,
        # Question
        :question_line1,
        # Resolution
        :resolution_by,
        :speech_by,
        # Unpredicted
        :heading, # Top-level headings may have no speeches
        :other, # "NOTICES OF MOTION UNDER RULE 32(3)" transitions to "Tabled April 28, 2014"
        :speech,
      ],

      subheading_begin: [:subheading],
      subheading: [
        :heading, # "Pursuant to Rule 30" transitions to "QUESTION NO. 1"
        :subheading, # "Given on May 16, 2011" transitions to "(Pursuant to Rule 30)"
      ],

      other_begin: [
        :other,
        :heading, # If no bills in "INTRODUCTION OF BILLS"
        :speech, # If a speaker interjects at the start of "INTRODUCTION OF BILLS"
      ],
      other: [
        :heading, # "Tabled May 1, 2014" transitions to "NOTICES OF MOTION UNDER RULE 32(3)"
        :other, # The bills in "INTRODUCTION OF BILLS"
        :speech, # The bills in "INTRODUCTION OF BILLS" transition to a speech
      ],

      question_line1: [:question_line2],
      question_line2: [:question],
      question: [:question_continue],
      question_continue: [
        :question_continue,
        :heading,
      ],

      answer: [:answer_continue],
      answer_continue: [
        :answer_continue,
        :heading,
      ],

      resolution_by: [:resolution],
      resolution: [:resolution_continue],
      resolution_continue: [
        :resolution_continue,
        :heading,
        :other, # "Tabled April 29, 2014"
      ],

      narrative: [
        # Multi-line narrative
        :narrative_continue,
        # One-line narrative
        :division,
        :heading,
        :narrative,
        :recorded_time,
        :speech,
      ],
      narrative_continue: [
        # Multi-line narrative
        :narrative_continue,
        # Closed narrative
        :speech_begin,
        # There is a single unclosed narrative: "The Speaker and the Clerks left the Chamber."
        # @see http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12dec06/
      ],
    }

    # A map between speaker names and URLs, for cases where we have only a name,
    # and to have consistent URLs for names.
    @speaker_urls = {}

    # A map between URLs and person IDs.
    @speaker_ids = {}
  end

  def initial_state?
    @state == @initial_state
  end

  def can_transition_to?(to)
    @transitions.key?(@state) && @transitions[@state].include?(to)
  end

  def transition_to(to)
    unless can_transition_to?(to)
      error("Illegal transition from #{@state} to #{to} (previously #{@previous_state}) #{@a[:href]}")
      if @speech
        warn("speech:\n#{JSON.pretty_generate(@speech)}")
      end
      if @previous_speech
        warn("previous speech:\n#{JSON.pretty_generate(@previous_speech)}")
      end
    end
    @previous_state = @state
    @state = to
  end
end

require_relative 'models'
require_relative 'constants'
require_relative 'people'
require_relative 'speeches'
require_relative 'akoma_ntoso'

NovaScotia.add_scraping_task(:people)
NovaScotia.add_scraping_task(:speeches)

options = {
  database_url: 'mongodb://localhost:27017/sayit',
  expires_in: 604800, # 1 week
}

if ENV['REDISCLOUD_URL']
  options[:output_dir] = ENV['REDISCLOUD_URL']
end

if ENV['MEMCACHIER_SERVERS']
  options[:cache_dir] = "memcached://#{ENV['MEMCACHIER_SERVERS']}"
  options[:memcached_username] = ENV['MEMCACHIER_USERNAME']
  options[:memcached_password] = ENV['MEMCACHIER_PASSWORD']
end

runner = Pupa::Runner.new(NovaScotia, options)

runner.add_action(name: 'akoma_ntoso', description: 'Output speeches as Akoma Ntoso')
runner.run(ARGV)
