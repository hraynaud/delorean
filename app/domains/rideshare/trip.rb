module Rideshare
  class Trip < ActiveRecord::Base
    belongs_to :service_tier
    has_many :trip_pool_trips
    has_one :trip_pool, through: :trip_pool_trips
    belongs_to :driver, foreign_key: :driver_id, class_name: Identity::User
    belongs_to :passenger, foreign_key: :passenger_id, class_name: Identity::User
    belongs_to :vehicle
    # belongs_to :order, class_name: FoodDelivery::Order
    has_one :payment

    scope :hailing, -> { where(driver_id: nil) }

    def order
      food_delivery_adapter.order_from_trip(self)
    end

    def food_delivery_adapter
      FoodDeliveryAdapter.new
    end

    def cost
      service_tier.rate * time_distance_traveled
    end

    def time_distance_traveled
      (origin_date - destination_date).abs
    end

    def in_progress?
      is_in_progress?
    end

    def hailing?
      driver.blank?
    end

    def completed?
      !!(driver && passenger)
    end

    def create_invoice!
      i = Invoice.find_or_initialize_by(trip: self)
      i.update(amount: cost, user: passenger)
      i
    end

    def paid?
      payment.present?
    end
  end
end
