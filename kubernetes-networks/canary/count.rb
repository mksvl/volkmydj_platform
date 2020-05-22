counts = Hash.new(0)
1000.times do
  output = `curl -s -H "Host: echo.com" http://172.17.255.2 | grep 'pod namespace'`
  counts[output.strip.split.last] += 1
end
puts counts
