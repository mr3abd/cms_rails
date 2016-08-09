class DomainConstraint
  def initialize(*domains)
    @domains = domains.flatten
    # if @domains.is_a?(Array)
    #   @domains = [domain].flatten
    # end
  end

  def matches?(request)
    Rails.logger.info "test"
    Rails.logger.info "matches?: @domains: #{@domains.inspect}"
    Rails.logger.info "matches?: request.domain: #{request.domain}"
    @domains.include? request.domain
  end
end
