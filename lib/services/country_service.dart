import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class CountryService {
  static const _baseUrl = 'https://restcountries.com/v3.1';

  Future<List<Country>> searchCountries(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/name/$trimmed');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as List<dynamic>;
        return body
            .map((e) => Country.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return _mockFilter(trimmed);
  }

  Future<List<Country>> getAllCountries() async {
    try {
      final uri = Uri.parse('$_baseUrl/all');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as List<dynamic>;
        return body
            .map((e) => Country.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return List.from(_mockCountries);
  }

  List<Country> _mockFilter(String query) {
    final q = query.toLowerCase();
    final results = _mockCountries.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.capitalText.toLowerCase().contains(q) ||
          c.region.toLowerCase().contains(q);
    }).toList();
    if (results.isEmpty) return List.from(_mockCountries);
    return results;
  }
}

final countryService = CountryService();

const _mockCountries = [
  Country(
    name: 'Thailand',
    officialName: 'Kingdom of Thailand',
    cca2: 'TH',
    cca3: 'THA',
    flagPng: 'https://flagcdn.com/w320/th.png',
    flagEmoji: '🇹🇭',
    capital: ['Bangkok'],
    region: 'Asia',
    subregion: 'South-Eastern Asia',
    languages: {'tha': 'Thai'},
    currencies: {'THB': CurrencyInfo(name: 'Thai baht', symbol: '฿')},
    area: 513120,
    population: 69799978,
    timezones: ['UTC+07:00'],
    borders: ['MMR', 'KHM', 'LAO', 'MYS'],
    latlng: [15.0, 100.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/5mYsJLBTwVgLe9rY9',
    callingCode: '+66',
    carSide: 'left',
    continents: ['Asia'],
  ),
  Country(
    name: 'Japan',
    officialName: 'Japan',
    cca2: 'JP',
    cca3: 'JPN',
    flagPng: 'https://flagcdn.com/w320/jp.png',
    flagEmoji: '🇯🇵',
    capital: ['Tokyo'],
    region: 'Asia',
    subregion: 'Eastern Asia',
    languages: {'jpn': 'Japanese'},
    currencies: {'JPY': CurrencyInfo(name: 'Japanese yen', symbol: '¥')},
    area: 377930,
    population: 125836021,
    timezones: ['UTC+09:00'],
    borders: [],
    latlng: [36.0, 138.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/NGQgJwHmhBFTBj4A8',
    callingCode: '+81',
    carSide: 'left',
    continents: ['Asia'],
  ),
  Country(
    name: 'United States',
    officialName: 'United States of America',
    cca2: 'US',
    cca3: 'USA',
    flagPng: 'https://flagcdn.com/w320/us.png',
    flagEmoji: '🇺🇸',
    capital: ['Washington, D.C.'],
    region: 'Americas',
    subregion: 'North America',
    languages: {'eng': 'English'},
    currencies: {'USD': CurrencyInfo(name: 'United States dollar', symbol: '\$')},
    area: 9372610,
    population: 329484123,
    timezones: ['UTC-12:00', 'UTC-11:00', 'UTC-10:00', 'UTC-09:00', 'UTC-08:00', 'UTC-07:00', 'UTC-06:00', 'UTC-05:00', 'UTC-04:00'],
    borders: ['CAN', 'MEX'],
    latlng: [38.0, -97.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/e8VpGcrHv3QVqFvM8',
    callingCode: '+1',
    carSide: 'right',
    continents: ['North America'],
  ),
  Country(
    name: 'United Kingdom',
    officialName: 'United Kingdom of Great Britain and Northern Ireland',
    cca2: 'GB',
    cca3: 'GBR',
    flagPng: 'https://flagcdn.com/w320/gb.png',
    flagEmoji: '🇬🇧',
    capital: ['London'],
    region: 'Europe',
    subregion: 'Northern Europe',
    languages: {'eng': 'English'},
    currencies: {'GBP': CurrencyInfo(name: 'British pound', symbol: '£')},
    area: 242900,
    population: 67215293,
    timezones: ['UTC-08:00', 'UTC+00:00', 'UTC+01:00'],
    borders: ['IRL'],
    latlng: [55.0, -3.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/FoGTC58HzLGFNsne7',
    callingCode: '+44',
    carSide: 'left',
    continents: ['Europe'],
  ),
  Country(
    name: 'France',
    officialName: 'French Republic',
    cca2: 'FR',
    cca3: 'FRA',
    flagPng: 'https://flagcdn.com/w320/fr.png',
    flagEmoji: '🇫🇷',
    capital: ['Paris'],
    region: 'Europe',
    subregion: 'Western Europe',
    languages: {'fra': 'French'},
    currencies: {'EUR': CurrencyInfo(name: 'Euro', symbol: '€')},
    area: 640679,
    population: 67391582,
    timezones: ['UTC-10:00', 'UTC-09:30', 'UTC-09:00', 'UTC-08:00', 'UTC-04:00', 'UTC-03:00', 'UTC+01:00', 'UTC+02:00', 'UTC+03:00', 'UTC+04:00', 'UTC+05:00', 'UTC+11:00', 'UTC+12:00'],
    borders: ['AND', 'BEL', 'DEU', 'ITA', 'LUX', 'MCO', 'ESP', 'CHE'],
    latlng: [46.0, 2.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/TSOhGjRpj8QrLUFU9',
    callingCode: '+33',
    carSide: 'right',
    continents: ['Europe'],
  ),
  Country(
    name: 'Australia',
    officialName: 'Commonwealth of Australia',
    cca2: 'AU',
    cca3: 'AUS',
    flagPng: 'https://flagcdn.com/w320/au.png',
    flagEmoji: '🇦🇺',
    capital: ['Canberra'],
    region: 'Oceania',
    subregion: 'Australia and New Zealand',
    languages: {'eng': 'English'},
    currencies: {'AUD': CurrencyInfo(name: 'Australian dollar', symbol: '\$')},
    area: 7692024,
    population: 25687041,
    timezones: ['UTC+05:00', 'UTC+06:30', 'UTC+07:00', 'UTC+08:00', 'UTC+09:30', 'UTC+10:00', 'UTC+10:30', 'UTC+11:30'],
    borders: [],
    latlng: [-27.0, 133.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/D7hMjWCVcPM7W2mN7',
    callingCode: '+61',
    carSide: 'left',
    continents: ['Oceania'],
  ),
  Country(
    name: 'Brazil',
    officialName: 'Federative Republic of Brazil',
    cca2: 'BR',
    cca3: 'BRA',
    flagPng: 'https://flagcdn.com/w320/br.png',
    flagEmoji: '🇧🇷',
    capital: ['Brasília'],
    region: 'Americas',
    subregion: 'South America',
    languages: {'por': 'Portuguese'},
    currencies: {'BRL': CurrencyInfo(name: 'Brazilian real', symbol: 'R\$')},
    area: 8515767,
    population: 212559417,
    timezones: ['UTC-05:00', 'UTC-04:00', 'UTC-03:00', 'UTC-02:00'],
    borders: ['ARG', 'BOL', 'COL', 'GUF', 'GUY', 'PRY', 'PER', 'SUR', 'URY', 'VEN'],
    latlng: [-10.0, -55.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/6hU7J9kPYMaNBZyv6',
    callingCode: '+55',
    carSide: 'right',
    continents: ['South America'],
  ),
  Country(
    name: 'India',
    officialName: 'Republic of India',
    cca2: 'IN',
    cca3: 'IND',
    flagPng: 'https://flagcdn.com/w320/in.png',
    flagEmoji: '🇮🇳',
    capital: ['New Delhi'],
    region: 'Asia',
    subregion: 'Southern Asia',
    languages: {'eng': 'English', 'hin': 'Hindi', 'tam': 'Tamil'},
    currencies: {'INR': CurrencyInfo(name: 'Indian rupee', symbol: '₹')},
    area: 3287590,
    population: 1380004385,
    timezones: ['UTC+05:30'],
    borders: ['BGD', 'BTN', 'MMR', 'CHN', 'NPL', 'PAK'],
    latlng: [20.0, 77.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/METaEgMDyNvSMdZM9',
    callingCode: '+91',
    carSide: 'left',
    continents: ['Asia'],
  ),
  Country(
    name: 'Germany',
    officialName: 'Federal Republic of Germany',
    cca2: 'DE',
    cca3: 'DEU',
    flagPng: 'https://flagcdn.com/w320/de.png',
    flagEmoji: '🇩🇪',
    capital: ['Berlin'],
    region: 'Europe',
    subregion: 'Western Europe',
    languages: {'deu': 'German'},
    currencies: {'EUR': CurrencyInfo(name: 'Euro', symbol: '€')},
    area: 357114,
    population: 83240525,
    timezones: ['UTC+01:00', 'UTC+02:00'],
    borders: ['AUT', 'BEL', 'CZE', 'DNK', 'FRA', 'LUX', 'NLD', 'POL', 'CHE'],
    latlng: [51.0, 9.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/LLcpbcJb2XqfxCsD7',
    callingCode: '+49',
    carSide: 'right',
    continents: ['Europe'],
  ),
  Country(
    name: 'South Africa',
    officialName: 'Republic of South Africa',
    cca2: 'ZA',
    cca3: 'ZAF',
    flagPng: 'https://flagcdn.com/w320/za.png',
    flagEmoji: '🇿🇦',
    capital: ['Pretoria', 'Bloemfontein', 'Cape Town'],
    region: 'Africa',
    subregion: 'Southern Africa',
    languages: {'afr': 'Afrikaans', 'eng': 'English', 'nbl': 'Southern Ndebele', 'nso': 'Northern Sotho', 'sot': 'Southern Sotho', 'ssw': 'Swazi', 'tsn': 'Tswana', 'tso': 'Tsonga', 'ven': 'Venda', 'xho': 'Xhosa', 'zul': 'Zulu'},
    currencies: {'ZAR': CurrencyInfo(name: 'South African rand', symbol: 'R')},
    area: 1221037,
    population: 59308690,
    timezones: ['UTC+02:00'],
    borders: ['BWA', 'LSO', 'MOZ', 'NAM', 'SWZ', 'ZWE'],
    latlng: [-29.0, 24.0],
    landlocked: false,
    unMember: true,
    googleMapsUrl: 'https://goo.gl/maps/1TvU2T6Z5h4yVFKd9',
    callingCode: '+27',
    carSide: 'left',
    continents: ['Africa'],
  ),
];
