# frozen_string_literal: true

class ProblemCheck::PollPop3Timeout < ProblemCheck
  self.priority = "low"

  def call
    # The logic of this problem check is performed inline, so this class is
    # purely here to support its configuration.
    #
    no_problem
  end
end
