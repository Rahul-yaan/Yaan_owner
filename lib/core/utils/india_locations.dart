/// Comprehensive location and road data across Indian States, Union Territories,
/// major cities, highways, and transport corridors.
class IndiaLocationData {
  /// All 28 States and 8 Union Territories in India (Alphabetical)
  static const List<String> states = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  /// Comprehensive mapping of each State/UT to its major cities, highway hubs, and transport towns
  static const Map<String, List<String>> stateCities = {
    'Andhra Pradesh': [
      'Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Kakinada',
      'Rajahmundry', 'Kadapa', 'Tirupati', 'Anantapur', 'Vizianagaram', 'Eluru',
      'Nandyal', 'Ongole', 'Adoni', 'Madanapalle', 'Machilipatnam', 'Tenali',
      'Proddatur', 'Chittoor', 'Hindupur', 'Srikakulam', 'Bhimavaram', 'Tadepalligudem',
      'Guntakal', 'Dharmavaram', 'Gudivada', 'Narasaraopet', 'Kadiri', 'Tadipatri',
      'Mangalagiri', 'Chilakaluripet', 'Bapatla', 'Rayachoti', 'Kavali'
    ],
    'Arunachal Pradesh': [
      'Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro', 'Tezu',
      'Bomdila', 'Roing', 'Aalo', 'Namsai', 'Changlang', 'Khonsa'
    ],
    'Assam': [
      'Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon', 'Tinsukia',
      'Tezpur', 'Bongaigaon', 'Diphu', 'Dhubri', 'North Lakhimpur', 'Sivasagar',
      'Goalpara', 'Karimganj', 'Golaghat', 'Barpeta', 'Hailakandi', 'Lumding',
      'Mangaldai', 'Hojai', 'Rangia', 'Kokrajhar', 'Margherita'
    ],
    'Bihar': [
      'Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia', 'Darbhanga',
      'Bihar Sharif', 'Arrah', 'Begusarai', 'Katihar', 'Munger', 'Chhapra',
      'Danapur', 'Bettiah', 'Saharsa', 'Sasaram', 'Hajipur', 'Dehri',
      'Siwan', 'Motihari', 'Nawada', 'Bagaha', 'Buxar', 'Kishanganj',
      'Sitamarhi', 'Jamalpur', 'Jehanabad', 'Aurangabad', 'Lakhisarai', 'Samastipur',
      'Bhabua', 'Madhubani', 'Gopalganj', 'Supaul', 'Araria', 'Forbesganj'
    ],
    'Chhattisgarh': [
      'Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Rajnandgaon', 'Jagdalpur',
      'Raigarh', 'Ambikapur', 'Mahasamund', 'Dhamtari', 'Durg', 'Chirmiri',
      'Bhatapara', 'Dalli-Rajhara', 'Kawardha', 'Kanker', 'Kondagaon', 'Jashpur',
      'Mungeli', 'Sakti', 'Gariaband', 'Bemetara', 'Balod'
    ],
    'Goa': [
      'Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda', 'Bicholim',
      'Curchorem', 'Cuncolim', 'Quepem', 'Canacona', 'Porvorim', 'Calangute'
    ],
    'Gujarat': [
      'Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar',
      'Junagadh', 'Gandhinagar', 'Anand', 'Navsari', 'Morbi', 'Bharuch',
      'Porbandar', 'Vapi', 'Mehsana', 'Bhuj', 'Valsad', 'Surendranagar',
      'Godhra', 'Palanpur', 'Ankleshwar', 'Gandhidham', 'Veraval', 'Dahod',
      'Botad', 'Amreli', 'Deesa', 'Patan', 'Jetpur', 'Kalol', 'Dholera',
      'Mundra', 'Keshod', 'Modasa', 'Himmatnagar', 'Halol', 'Bardoli'
    ],
    'Haryana': [
      'Gurgaon', 'Faridabad', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak',
      'Hisar', 'Karnal', 'Sonipat', 'Panchkula', 'Bhiwani', 'Sirsa',
      'Bahadurgarh', 'Jind', 'Thanesar', 'Kaithal', 'Rewari', 'Palwal',
      'Hansi', 'Narnaul', 'Fatehabad', 'Gohana', 'Tohana', 'Narwana',
      'Manesar', 'Kurukshetra', 'Dharuhera', 'Bawal', 'Kundli', 'Murthal'
    ],
    'Himachal Pradesh': [
      'Shimla', 'Dharamshala', 'Solan', 'Mandi', 'Baddi', 'Nahan',
      'Paonta Sahib', 'Sundarnagar', 'Chamba', 'Kullu', 'Una', 'Hamirpur',
      'Bilaspur', 'Nalagarh', 'Nurpur', 'Kangra', 'Manali', 'Parwanoo',
      'Kalka', 'Palampur', 'Chail', 'Kasauli'
    ],
    'Jharkhand': [
      'Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro Steel City', 'Deoghar', 'Phusro',
      'Hazaribagh', 'Giridih', 'Ramgarh', 'Medininagar', 'Chirkunda', 'Chaibasa',
      'Gumla', 'Dumka', 'Godda', 'Sahibganj', 'Simdega', 'Koderma',
      'Chakradharpur', 'Ghatshila', 'Jhumri Telaiya', 'Bermo', 'Pakur'
    ],
    'Karnataka': [
      'Bangalore', 'Mysore', 'Hubli', 'Dharwad', 'Mangalore', 'Belgaum',
      'Gulbarga', 'Davanagere', 'Bellary', 'Shimoga', 'Tumkur', 'Bidar',
      'Hospet', 'Hassan', 'Gadag', 'Udupi', 'Raichur', 'Bijapur',
      'Robertsonpet', 'Chikkamagaluru', 'Bagalkot', 'Chitradurga', 'Kolar', 'Mandya',
      'Haveri', 'Karwar', 'Ranebennur', 'Yadgir', 'Chamarajanagar', 'Koppal',
      'Bhadravati', 'Nipani', 'Sirsi', 'Sindhanur', 'Gokak', 'Dandeli'
    ],
    'Kerala': [
      'Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Kollam', 'Thrissur', 'Kannur',
      'Alappuzha', 'Kottayam', 'Palakkad', 'Manjeri', 'Thalassery', 'Thrippunithura',
      'Ponnani', 'Vatakara', 'Kanhangad', 'Payyanur', 'Koyilandy', 'Parappanangadi',
      'Kalamassery', 'Kodungallur', 'Neyyattinkara', 'Tanur', 'Kayamkulam', 'Malappuram',
      'Guruvayur', 'Attingal', 'Kasargod', 'Changanassery', 'Perinthalmanna'
    ],
    'Madhya Pradesh': [
      'Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar',
      'Dewas', 'Satna', 'Ratlam', 'Rewa', 'Katni', 'Singrauli',
      'Burhanpur', 'Khandwa', 'Bhind', 'Chhindwara', 'Guna', 'Shivpuri',
      'Vidisha', 'Chhatarpur', 'Damoh', 'Mandsaur', 'Khargone', 'Neemuch',
      'Pithampur', 'Hoshangabad', 'Itarsi', 'Sehore', 'Betul', 'Seoni',
      'Datia', 'Nagda', 'Dhar', 'Balaghat', 'Barwani', 'Mandla', 'Shahdol'
    ],
    'Maharashtra': [
      'Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane', 'Aurangabad',
      'Solapur', 'Amravati', 'Navi Mumbai', 'Kolhapur', 'Akola', 'Panvel',
      'Ulhasnagar', 'Sangli', 'Malegaon', 'Jalgaon', 'Latur', 'Dhule',
      'Ahmednagar', 'Chandrapur', 'Parbhani', 'Jalna', 'Bhiwandi', 'Ichalkaranji',
      'Nanded', 'Satara', 'Wardha', 'Gondia', 'Yavatmal', 'Baramati',
      'Bhusawal', 'Kalyan', 'Dombivli', 'Mira-Bhayandar', 'Vasai-Virar', 'Ratnagiri'
    ],
    'Manipur': [
      'Imphal', 'Thoubal', 'Bishnupur', 'Churachandpur', 'Kakching', 'Ukhrul',
      'Senapati', 'Tamenglong', 'Jiribam', 'Kangpokpi'
    ],
    'Meghalaya': [
      'Shillong', 'Tura', 'Nongpoh', 'Jowai', 'Cherrapunji', 'Baghmara',
      'Williamnagar', 'Resubelpara', 'Mairang'
    ],
    'Mizoram': [
      'Aizawl', 'Lunglei', 'Champhai', 'Serchhip', 'Kolasib', 'Lawngtlai',
      'Saitual', 'Mamit', 'Khawzawl', 'Hnahthial'
    ],
    'Nagaland': [
      'Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha', 'Zunheboto',
      'Mon', 'Phek', 'Kiphire', 'Longleng', 'Chumoukedima'
    ],
    'Odisha': [
      'Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur', 'Puri',
      'Balasore', 'Bhadrak', 'Baripada', 'Jharsuguda', 'Jeypore', 'Bargarh',
      'Rayagada', 'Bolangir', 'Jatani', 'Angul', 'Dhenkanal', 'Kendujhar',
      'Paradip', 'Sunabeda', 'Bhawanipatna', 'Talcher', 'Koraput'
    ],
    'Punjab': [
      'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali',
      'Hoshiarpur', 'Batala', 'Pathankot', 'Moga', 'Abohar', 'Malerkotla',
      'Khanna', 'Muktsar', 'Barnala', 'Firozpur', 'Kapurthala', 'Phagwara',
      'Rajpura', 'Zirakpur', 'Sangrur', 'Fazilka', 'Mansa', 'Gurdaspur',
      'Nawanshahr', 'Ropar', 'Tarn Taran', 'Faridkot', 'Sunam'
    ],
    'Rajasthan': [
      'Jaipur', 'Jodhpur', 'Kota', 'Bikaner', 'Ajmer', 'Udaipur',
      'Bhilwara', 'Alwar', 'Bharatpur', 'Sikar', 'Pali', 'Sri Ganganagar',
      'Kishangarh', 'Baran', 'Dholpur', 'Tonk', 'Beawar', 'Hanumangarh',
      'Sawai Madhopur', 'Churu', 'Jhunjhunu', 'Chittorgarh', 'Bundi', 'Nagaur',
      'Barmer', 'Jaisalmer', 'Banswara', 'Dungarpur', 'Mount Abu', 'Hindaun',
      'Bhiwadi', 'Neemrana', 'Kotputli', 'Makrana', 'Sujangarh', 'Didwana'
    ],
    'Sikkim': [
      'Gangtok', 'Namchi', 'Geyzing', 'Mangan', 'Rangpo', 'Singtam',
      'Jorethang', 'Ravangla', 'Pelling'
    ],
    'Tamil Nadu': [
      'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli',
      'Tiruppur', 'Ranipet', 'Nagercoil', 'Thanjavur', 'Vellore', 'Kancheepuram',
      'Erode', 'Tiruvannamalai', 'Pollachi', 'Rajapalayam', 'Sivakasi', 'Pudukkottai',
      'Neyveli', 'Nagapattinam', 'Viluppuram', 'Tiruchengode', 'Vaniyambadi', 'Theni',
      'Ooty', 'Arakkonam', 'Kumarapalayam', 'Karaikudi', 'Hosur', 'Dindigul',
      'Thoothukudi', 'Cuddalore', 'Kumbakonam', 'Ambur', 'Namakkal', 'Karur'
    ],
    'Telangana': [
      'Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Ramagundam', 'Khammam',
      'Mahbubnagar', 'Nalgonda', 'Adilabad', 'Suryapet', 'Miryalaguda', 'Siddipet',
      'Jagtial', 'Mancherial', 'Nirmal', 'Kamareddy', 'Kothagudem', 'Bodhan',
      'Palwancha', 'Mandamarri', 'Secunderabad', 'Sangareddy', 'Medak', 'Zaheerabad'
    ],
    'Tripura': [
      'Agartala', 'Dharmanagar', 'Udaipur', 'Kailashahar', 'Belonia', 'Khowai',
      'Teliamura', 'Ambassa', 'Sabroom', 'Melaghar'
    ],
    'Uttar Pradesh': [
      'Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Meerut', 'Varanasi',
      'Prayagraj', 'Bareilly', 'Aligarh', 'Moradabad', 'Saharanpur', 'Gorakhpur',
      'Noida', 'Firozabad', 'Jhansi', 'Muzaffarnagar', 'Mathura', 'Budaun',
      'Rampur', 'Shahjahanpur', 'Farrukhabad', 'Ayodhya', 'Maunath Bhanjan', 'Hapur',
      'Etawah', 'Mirzapur', 'Bulandshahr', 'Sambhal', 'Amroha', 'Hardoi',
      'Fatehpur', 'Raebareli', 'Orai', 'Sitapur', 'Bahraich', 'Modinagar',
      'Unnao', 'Jaunpur', 'Lakhimpur', 'Hathras', 'Banda', 'Pilibhit',
      'Barabanki', 'Kasganj', 'Greater Noida', 'Basti', 'Ballia', 'Chandausi'
    ],
    'Uttarakhand': [
      'Dehradun', 'Haridwar', 'Roorkee', 'Haldwani', 'Rudrapur', 'Kashipur',
      'Rishikesh', 'Pithoragarh', 'Ramnagar', 'Manglaur', 'Jaspur', 'Kichha',
      'Nainital', 'Mussoorie', 'Kotdwar', 'Tehri', 'Chamoli', 'Uttarkashi',
      'Pantnagar', 'Almora', 'Bageshwar', 'Ranikhet', 'Vikasnagar'
    ],
    'West Bengal': [
      'Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri', 'Bardhaman',
      'Malda', 'Baharampur', 'Habra', 'Kharagpur', 'Shantipur', 'Dankuni',
      'Dhulian', 'Ranaghat', 'Haldia', 'Raiganj', 'Krishnanagar', 'Nabadwip',
      'Midnapore', 'Jalpaiguri', 'Balurghat', 'Basirhat', 'Bankura', 'Chakdaha',
      'Darjeeling', 'Alipurduar', 'Purulia', 'Cooch Behar', 'Bangaon', 'Bhatpara'
    ],
    // Union Territories
    'Andaman and Nicobar Islands': [
      'Port Blair', 'Diglipur', 'Mayabunder', 'Rangat', 'Car Nicobar', 'Havelock Island'
    ],
    'Chandigarh': [
      'Chandigarh', 'Manimajra'
    ],
    'Dadra and Nagar Haveli and Daman and Diu': [
      'Daman', 'Diu', 'Silvassa', 'Amli', 'Dadra', 'Naroli'
    ],
    'Delhi': [
      'New Delhi', 'Central Delhi', 'North Delhi', 'South Delhi', 'East Delhi',
      'West Delhi', 'North East Delhi', 'North West Delhi', 'South West Delhi',
      'South East Delhi', 'Shahdara', 'Dwarka', 'Rohini', 'Connaught Place',
      'Karol Bagh', 'Saket', 'Vasant Kunj', 'Mahipalpur', 'Janakpuri', 'Laxmi Nagar'
    ],
    'Jammu and Kashmir': [
      'Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Udhampur', 'Kathua',
      'Sopore', 'Bandipora', 'Pulwama', 'Kupwara', 'Poonch', 'Rajouri',
      'Kulgam', 'Ganderbal', 'Shopian', 'Budgam', 'Samba', 'Reasi', 'Kishtwar'
    ],
    'Ladakh': [
      'Leh', 'Kargil', 'Diskit', 'Drass', 'Nubra', 'Chushul'
    ],
    'Lakshadweep': [
      'Kavaratti', 'Agatti', 'Andrott', 'Amini', 'Kalpeni', 'Minicoy'
    ],
    'Puducherry': [
      'Puducherry', 'Karaikal', 'Yanam', 'Mahe', 'Ozhukarai'
    ],
  };

  /// Common National Highways, Expressways, and bypass roads applicable across India
  static const List<String> majorHighwaysAndRoads = [
    'NH 48 (Delhi - Mumbai - Chennai Highway)',
    'NH 44 (Srinagar - Kanyakumari Highway)',
    'NH 27 (Porbandar - Silchar East-West Highway)',
    'NH 19 (Delhi - Kolkata GT Road)',
    'NH 52 (Punjab - Rajasthan - Karnataka Highway)',
    'NH 65 (Pune - Hyderabad - Machilipatnam Highway)',
    'NH 16 (Kolkata - Chennai Highway)',
    'NH 8 (Delhi - Jaipur - Ahmedabad - Mumbai)',
    'NH 53 (Surat - Nagpur - Kolkata Highway)',
    'NH 66 (Mumbai - Goa - Kochi Highway)',
    'NH 75 (Bangalore - Mangalore Highway)',
    'NH 43 (Raipur - Jagdalpur - Visakhapatnam)',
    'NH 30 (Uttarakhand - Andhra Pradesh Highway)',
    'NH 21 (Jaipur - Agra - Bareilly Highway)',
    'Delhi-Mumbai Expressway',
    'Mumbai-Pune Expressway',
    'Yamuna Expressway',
    'Agra-Lucknow Expressway',
    'Samruddhi Mahamarg (Mumbai - Nagpur Expressway)',
    'Purvanchal Expressway',
    'Bundelkhand Expressway',
    'Ahmedabad-Vadodara Expressway',
    'Eastern Peripheral Expressway',
    'Western Peripheral Expressway (KMP)',
    'Outer Ring Road',
    'Inner Ring Road',
    'Bypass Road',
    'Highway Bypass Road',
    'Service Road',
    'Transport Nagar Road',
    'Industrial Area Main Road',
    'Airport Road',
    'Station Road',
    'Grand Trunk Road (GT Road)',
  ];

  /// Specific roads for major transport/commercial cities
  static const Map<String, List<String>> cityRoads = {
    'Ahmedabad': [
      'CG Road', 'SG Highway', 'Ashram Road', 'SP Ring Road',
      'Narol Highway', 'Sarkhej Highway', 'Sanand Highway',
      'Naroda Road', 'Vastral Ring Road', 'Drive-in Road', 'Sindhu Bhavan Road'
    ],
    'Surat': [
      'Ring Road', 'Dumas Road', 'VIP Road', 'Hazira Highway',
      'Kamrej Highway', 'Udhna-Navsari Road', 'Varachha Main Road',
      'Ghod Dod Road', 'Katargam Road', 'Adajan Road'
    ],
    'Vadodara': [
      'RC Dutt Road', 'Sayajigunj', 'Old Padra Road', 'Halol Highway',
      'Waghodia Road', 'Makarpura GIDC Road', 'Alkapuri Road', 'Ajwa Road'
    ],
    'Rajkot': [
      'Kalawad Road', '150 Feet Ring Road', 'Gondal Road', 'Yagnik Road',
      'Kuvadva Road', 'University Road', 'Mavdi Main Road'
    ],
    'Mumbai': [
      'Western Express Highway (WEH)', 'Eastern Express Highway (EEH)',
      'Marine Drive', 'Linking Road', 'SV Road', 'LBS Marg',
      'Sion-Panvel Highway', 'Ghatkopar Mankhurd Link Road', 'Palm Beach Road',
      'Thane-Belapur Road', 'Ghodbunder Road'
    ],
    'Pune': [
      'FC Road', 'JM Road', 'MG Road', 'Baner Road', 'Mumbai-Bangalore Highway',
      'Pune-Solapur Highway', 'Pune-Nashik Highway', 'Nagar Road',
      'Hinjewadi IT Park Road', 'Senapati Bapat Road', 'Kothrud DP Road'
    ],
    'Nagpur': [
      'Wardha Road', 'Hingna Road', 'Amravati Road', 'Ring Road Nagpur',
      'Central Avenue', 'Kamptee Road', 'Umaria Road', 'Manewada Road'
    ],
    'Nashik': [
      'Mumbai-Agra Highway', 'Pune Road', 'Gangapur Road', 'College Road',
      'Trimbak Road', 'Dwarka Circle', 'Ambad MIDC Road'
    ],
    'New Delhi': [
      'Rajpath', 'Janpath', 'Ring Road Delhi', 'Outer Ring Road Delhi',
      'Mathura Road', 'GT Karnal Road', 'Rohtak Road', 'NH-8 Mahipalpur',
      'Connaught Place Inner Circle', 'Barakhamba Road', 'DND Flyway'
    ],
    'Bangalore': [
      'MG Road', 'Brigade Road', 'Outer Ring Road Bangalore', 'Hosur Road',
      'Tumkur Road', 'Bellary Road', 'Electronic City Expressway',
      'Whitefield Main Road', 'Bannerghatta Road', 'Mysore Road',
      'Old Madras Road', 'Kanakapura Road', 'Sarjapur Road'
    ],
    'Hyderabad': [
      'Outer Ring Road Hyderabad (ORR)', 'PVNR Expressway', 'NH 65 Vijayawada Highway',
      'NH 44 Nagpur Highway', 'Gachibowli Miyapur Road', 'Banjara Hills Road No 1',
      'Jubilee Hills Checkpost Road', 'Kukatpally Main Road', 'Secunderabad Station Road'
    ],
    'Chennai': [
      'Grand Southern Trunk Road (GST)', 'Grand Northern Trunk Road (GNT)',
      'Old Mahabalipuram Road (OMR)', 'East Coast Road (ECR)', 'Mount Road (Anna Salai)',
      'Mount-Poonamallee Road', 'Inner Ring Road Chennai', 'Poonamallee High Road'
    ],
    'Kolkata': [
      'EM Bypass', 'Kona Expressway', 'Belghoria Expressway', 'Jessore Road',
      'VIP Road Kolkata', 'Durgapur Expressway', 'Strand Road', 'AJC Bose Road'
    ],
    'Jaipur': [
      'Tonk Road', 'Ajmer Road', 'Sikar Road', 'Delhi Road', 'MI Road',
      'JLN Marg', 'Sirsi Road', 'Gopalpura Bypass', 'Agra Road'
    ],
    'Lucknow': [
      'Shaheed Path', 'Faizabad Road', 'Kanpur Road', 'Sitapur Road',
      'Hazratganj Main Road', 'Hardoi Road', 'Vibhuti Khand Road'
    ],
    'Indore': [
      'AB Road (Agra-Bombay)', 'Bypass Road Indore', 'Ring Road Indore',
      'MG Road Indore', 'Super Corridor', 'Ujjain Road', 'Khandwa Road'
    ],
    'Bhopal': [
      'Hoshangabad Road', 'Kolar Road', 'Raisen Road', 'VIP Road Bhopal',
      'Link Road No 1', 'Berasia Road', 'Airport Road Bhopal'
    ],
    'Chandigarh': [
      'Madhya Marg', 'Dakshin Marg', 'Himalaya Marg', 'Jan Marg',
      'Zirakpur Highway', 'Chandigarh-Ambala Highway'
    ],
    'Patna': [
      'Bailey Road', 'Boring Road', 'Kankarbagh Main Road', 'Ganga Pathway',
      'Patna-Bakhtiyarpur 4 Lane', 'Ashok Rajpath', 'Bypass Road Patna'
    ],
  };

  /// Flattened, unique, sorted list of all cities across India
  static final List<String> allCities = () {
    final Set<String> citySet = {};
    for (final list in stateCities.values) {
      citySet.addAll(list);
    }
    final sorted = citySet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(sorted);
  }();

  /// Reverse lookup: City name -> State name
  static final Map<String, String> cityToState = () {
    final Map<String, String> map = {};
    for (final entry in stateCities.entries) {
      for (final city in entry.value) {
        map[city.toLowerCase()] = entry.key;
      }
    }
    return Map<String, String>.unmodifiable(map);
  }();

  /// Returns cities for a given state, or all cities if state is null/empty.
  /// If query is provided, matches starting with query first, then containing query.
  static List<String> getCities({String? state, String query = ''}) {
    List<String> pool;
    if (state != null && state.isNotEmpty && stateCities.containsKey(state)) {
      pool = stateCities[state]!;
    } else {
      pool = allCities;
    }

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return pool;

    final startsWith = pool.where((c) => c.toLowerCase().startsWith(trimmed)).toList();
    final contains = pool.where((c) => !c.toLowerCase().startsWith(trimmed) && c.toLowerCase().contains(trimmed)).toList();
    return [...startsWith, ...contains];
  }

  /// Returns states matching query, with startsWith prioritized
  static List<String> getStates({String query = ''}) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return states;

    final startsWith = states.where((s) => s.toLowerCase().startsWith(trimmed)).toList();
    final contains = states.where((s) => !s.toLowerCase().startsWith(trimmed) && s.toLowerCase().contains(trimmed)).toList();
    return [...startsWith, ...contains];
  }

  /// Returns roads matching city and query
  static List<String> getRoads({String? city, String query = ''}) {
    final Set<String> poolSet = {};
    if (city != null && city.isNotEmpty && cityRoads.containsKey(city)) {
      poolSet.addAll(cityRoads[city]!);
    }
    poolSet.addAll(majorHighwaysAndRoads);

    final pool = poolSet.toList();
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return pool;

    final startsWith = pool.where((r) => r.toLowerCase().startsWith(trimmed)).toList();
    final contains = pool.where((r) => !r.toLowerCase().startsWith(trimmed) && r.toLowerCase().contains(trimmed)).toList();
    return [...startsWith, ...contains];
  }

  /// Reverse lookup to get State for a given city
  static String? getStateForCity(String city) {
    return cityToState[city.trim().toLowerCase()];
  }
}
