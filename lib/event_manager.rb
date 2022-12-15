require 'google/apis/civicinfo_v2'
puts 'Event Manager Initialized!'
require 'csv'
require 'erb'


contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

data = []

service = Google::Apis::CivicinfoV2::CivicInfoService.new
service.key = 'AIzaSyC-2HM4X-sdH-EExBBgBDZZg1JnQnQ_tjA'


#the following code populates a template with user information from the data array. It does the following:
# 1. Creates a new instance of the CivicInfoService class and assigns it to the service variable.
# 2. Sets the key property of the service object to your Google Civic Information API key.
# 3. Reads the template.erb file from the views directory and assigns the contents to the template_letter variable.
# 4. Creates a new instance of the ERB class and assigns it to the erb_template variable. The template_letter variable is passed as an argument to the ERB constructor.
# 5. Iterates over the rows in the CSV file using the contents.each loop.
# 6. For each row, the code extracts the name and zipcode values and uses them to call the representative_info_by_address method of the service object. This method returns information about the government representatives for the given zip code.
# 7. The code then maps the names of the representatives to an array and assigns it to the legislators variable.
# 8. The erb_template.result method is called, passing the binding of the current scope as an argument. This evaluates the ERB template and substitutes the name and legislators variables with their corresponding values from the data array. The resulting string is assigned to the personal_letter variable.
# 9. The personal_letter string is printed to the console.


template_letter = File.read("views/template.erb")
erb_template = ERB.new(template_letter)

contents.each do |row|
  name = row[:first_name]
  zipcode = row[:zipcode]

  begin
    civic_info = service.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials

    legislators = civic_info.map(&:name)

    personal_letter = erb_template.result(binding)

    puts personal_letter
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end



