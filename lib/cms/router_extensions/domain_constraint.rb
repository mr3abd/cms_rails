class DomainConstraint
  def initialize(*domains)
    @domains = domains.flatten
    # if @domains.is_a?(Array)
    #   @domains = [domain].flatten
    # end
  end

  def matches?(request)
    @domains.include? request.domain
  end
end
