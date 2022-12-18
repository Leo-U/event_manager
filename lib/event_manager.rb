require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_numbers(phone_num)
  #remove non-numeric chars:
  phone_num = phone_num.gsub(/[^0-9]/, "")
  #modify numbers per lesson instructions:
  if phone_num.length < 10 || phone_num.length > 11 || (phone_num.length == 11 && phone_num[0] != "1")
    phone_num = "0000000000"
  elsif phone_num.length == 11 && phone_num[0] == "1"
    phone_num.slice!(0)
  end
  #reformat phone number:
  phone_num = "(#{phone_num[0..2]}) #{phone_num[3..5]}-#{phone_num[6..9]}"
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def parse_time(time, hours, days)
  date_registered = Time.strptime(time, "%m/%d/%y %H:%M")
  day_registered = date_registered.strftime("%A")
  hour_registered = date_registered.hour
  hours << hour_registered
  days << day_registered
end

hours_registered = []
days_registered = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_num = clean_phone_numbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
  puts "name: #{name}, zipcode: #{zipcode}, phone number: #{phone_num}"
  parse_time(row[:regdate], hours_registered, days_registered)
end

def sort_by_frequency(times)
  times.tally.sort_by {|k, v| v}.reverse.to_h
end

hours_frequencies = sort_by_frequency(hours_registered)
hours_frequencies.transform_keys! { |key| key.to_s + ':00'}

days_frequencies = sort_by_frequency(days_registered)

def print_frequencies(title, frequencies)
  puts "\n#{title} occurences:"
  frequencies.each do |key, value|
    puts "#{key}: #{value}"
  end
end

print_frequencies("Registration hourly", hours_frequencies)
print_frequencies("Registration daily", days_frequencies)