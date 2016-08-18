class HostConstraint
  def initialize(*hosts)
    @hosts = hosts.flatten
    # if @domains.is_a?(Array)
    #   @domains = [domain].flatten
    # end
  end

  def matches?(request)
    @hosts.include? request.host
  end
end
