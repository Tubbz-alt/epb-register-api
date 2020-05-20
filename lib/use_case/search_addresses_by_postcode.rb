module UseCase
  class SearchAddressesByPostcode
    def initialize(address_search_gateway)
      @address_search_gateway = address_search_gateway
    end

    def execute(postcode:, building_name_number: nil, address_type: nil)
      @address_search_gateway.search_by_postcode postcode,
                                                 building_name_number,
                                                 address_type
    end
  end
end
