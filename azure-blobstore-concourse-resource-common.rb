require 'json'

def check_source
  if @storage_account_name.nil?
    STDERR.puts "storage_account_name is missing in source"
    exit 1
  end

  if @container.nil?
    STDERR.puts "container is missing in source"
    exit 1
  end

  if @regexp.nil?
    STDERR.puts "regexp is missing in source"
    exit 1
  end

  case @environment
  when  "AzureCloud" , nil
    @endpoint = "blob.core.windows.net"
  when "AzureChinaCloud"
    @endpoint = "blob.core.chinacloudapi.cn"
  else
    STDERR.puts "unsupported Azure environment #{@environment}. Should be AzureCloud or AzureChinaCloud"
    exit 1
  end
end

def get_names_and_versions
  client = Azure::Storage::Client.create(:storage_account_name => "#{@storage_account_name}", :storage_access_key => "#{@storage_access_key}")
  
  blob_client = client.blob_client
  blobs = blob_client.list_blobs("#{@container}")

  files = blobs.map {|blob| blob.name}
  matched_files = files.select {|file| file.match @regexp}

  names_and_versions = matched_files.map do |matched_file|
      version = matched_file.match(@regexp)[1]
      { "filename" => matched_file, "version" => version  }
  end

  names_and_versions.reject! { |h| h["version"].match(/[^0-9\.]/) }
  names_and_versions.sort! { |a,b| Gem::Version.new(a["version"]) <=> Gem::Version.new(b["version"])  }
end

def download_file(dest_dir,requested_path)
  client = Azure::Storage::Client.create(:storage_account_name => "#{@storage_account_name}", :storage_access_key => "#{@storage_access_key}")
  
  blob_client = client.blob_client

  blob, content = blob_client.get_blob("#{@container}", requested_path)
  ::File.open(File.join(dest_dir, blob.name), 'wb') {|f| f.write(content)}

  version = requested_path.match(@regexp)[1]
  ::File.open(File.join(dest_dir, "version"), "w+") {|f| f.write("#{version}")}

  blob.properties.delete_if {|key, value| value.nil? }
end

def upload_file(src_file,dst_path)
  client = Azure::Storage::Client.create(:storage_account_name => @storage_account_name, :storage_access_key => @storage_access_key)
  
  blob_client = client.blob_client

  content = ::File.open(src_file, 'rb') { |file| file.read }
  blob = blob_client.create_block_blob(@container, dst_path, content)
  
  blob.properties.delete_if {|key, value| value.nil? }
end
