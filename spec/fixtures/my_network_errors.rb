module MyNetworkErrors
  extend self

  ERRORS = [Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EFAULT].freeze

  def ===(error)
    ERRORS.any? { |error_class| error_class === error }
  end
end
