require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_numbers(phone_num)
  #remove non-numeric chars
  phone_num = phone_num.gsub(/[^0-9]/, "")
  #perform operations as per lesson instructions
  if phone_num.length < 10 || phone_num.length > 11 || (phone_num.length == 11 && phone_num[0] != "1")
    phone_num = "000-000-0000"
  elsif phone_num.length == 11 && phone_num[0] == "1"
    phone_num.slice!(0)
    phone_num
  else phone_num = phone_num
  end
  #re-format phone number:
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

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_num = clean_phone_numbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
  puts "name: #{name}, zipcode: #{zipcode}, phone number: #{phone_num}"
end