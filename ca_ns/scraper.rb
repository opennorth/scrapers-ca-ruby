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
      speech_continue: [
        :speech_continue,
        :division,
        :heading,
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

      heading_begin: [:heading],
      heading: [
        # Predicted
        :answer,
        :question_line1,
        :resolution_by,
        # Unpredicted
        :heading,
        :speech,
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
        # Unclosed narrative
        :narrative_continue,
        # Closed narrative
        :speech_begin,
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
      error(JSON.pretty_generate(@speech)) if @speech
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

runner = Pupa::Runner.new(NovaScotia, {
  database_url: 'mongodb://localhost:27017/sayit',
  expires_in: 604800, # 1 week
})
runner.add_action(name: 'akoma_ntoso', description: 'Output speeches as Akoma Ntoso')
runner.run(ARGV)
