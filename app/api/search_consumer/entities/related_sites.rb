module SearchConsumer
  module Entities
    class RelatedSites < Grape::Entity
      expose :related_sites_dropdown_label, as: :label, documentation: { type: 'string', desc: "The label for the related sites dropdown." }
      expose :connections, as: :sites, documentation: { type: 'array', desc: "Expose an array of objects containing information related to an affiliate's related sites" } do |affiliate|
        affiliate.connections.map do |connection|
          { id: connection.id,
            connected_affiliate_id: connection.connected_affiliate_id,
            label: connection.label,
            position: connection.position }
        end
      end
    end
  end
end
