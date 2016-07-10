object false

node(:draw) { params[:draw].to_i }
node(:recordsTotal) { @result.total }
node(:recordsFiltered) { @result.total }
node :data do
  @result.documents.map do |log|
    filtered = log["_source"].except("api_key", "_type", "_score", "_index").merge({
      "request_url" => strip_api_key_from_url(log["_source"]["request_url"]).gsub(%r{^.*://[^/]*}, "")
    })

    if(filtered["request_query"] && filtered["request_query"]["api_key"])
      filtered["request_query"].delete("api_key")
    end

    filtered
  end
end
