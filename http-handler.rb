module HttpHandler
  def logging_non_ok_responses(req, deferred)
    if req.response_header.status != 200
      @logger.error("Received status #{req.response_header.status}:")
      @logger.error(req.response)
      deferred.reject(req)
      return
    end

    yield
  end
end
