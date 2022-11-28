host_details = {
  host: 'localhost',
  port: 6379,
  db: '0'
}

begin
  REDIS = Redis.new(host_details)
  REDIS.get('RevaAppGuest')
rescue StandardError
  raise "Failed to connect host at\n#{host_details}"
end