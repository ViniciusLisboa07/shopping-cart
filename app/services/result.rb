# frozen_string_literal: true

class Result
  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.failure(error)
    new(success: false, error: error)
  end

  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def data
    raise "Cannot access data on failure result" unless success?
    @data
  end

  def error
    raise "Cannot access error on success result" unless failure?
    @error
  end
end
