class InvestmentController < ApplicationController

	Url = 'https://rest.coinapi.io/v1/assets'
	Api_key = '74AB2CC3-D183-47F8-A3B9-90DB525F1D4B'

	def quote
		if params[:csv_file].present?
			read_csv
			cripto_data
			render json: calculate_investment
		else
			render json: {error: ""}
		end

	end

	private
		def cripto_data
			@cripto_data = [
				{
					id: 'BTC',
					name: "Bitcoin",
					anual_percent: 5,
					amount_invest: amount_invest(@csv_data['porcentaje_bitcoin'])
				},
				{
					id: 'ETH',
					name: "Ethereum",
					anual_percent: 4.2,
					amount_invest: amount_invest(@csv_data['porcentaje_ether'])
				},
				{
					id: 'ADA',
					name: "Cardano",
					anual_percent: 1,
					amount_invest: amount_invest(@csv_data['porcentaje_cardano'])
				}
			]
		end
		
		def read_csv
			require 'csv'
			csv_data = params[:csv_file].read
			data = []
			CSV.parse(csv_data, headers: true) do |row|
				data << row.to_hash
      end
			@csv_data = data[0]
		end

		def amount_invest(investment_percent)
			@csv_data['inversion_dolares'].to_f*(investment_percent.to_f/100)
		end
		
		def calculate_investment
			investment_data = []
			@cripto_data.map do |cripto|
				price_cripto = get_price(cripto[:id])
				cripto_balance = cripto_balance(price_cripto, cripto[:amount_invest])
				balance_data = {
					name: cripto[:name],
					price_usd: price_cripto,
					cripto_balance: cripto_balance,
					month_return: month_return(cripto_balance, cripto[:anual_percent]),
					year_return: year_return(cripto_balance, cripto[:anual_percent])
				}
				investment_data << balance_data
			end
			investment_data
		end

		def get_price(cripto_id)
			require 'uri'
			require 'net/http'

			url = URI("https://rest.coinapi.io/v1/assets/#{cripto_id}")
			puts "-----------------------------------------"
			puts url
			http = Net::HTTP.new(url.host, url.port)
			request = Net::HTTP::Get.new(url)
			http.use_ssl = true
			request["X-CoinAPI-Key"] = '74AB2CC3-D183-47F8-A3B9-90DB525F1D4B'
			response = http.request(request)
			json_response = JSON.parse(response.read_body)
			json_response[0]['price_usd']
		end

		def cripto_balance(price_cripto, amount_invest)
			amount_invest.to_f/price_cripto
		end

		def month_return(cripto_balance, anual_percent)
			((anual_percent.to_f/100)/12) * cripto_balance
		end

		def year_return(cripto_balance, anual_percent)
			((anual_percent.to_f/100)) * cripto_balance
		end

end
