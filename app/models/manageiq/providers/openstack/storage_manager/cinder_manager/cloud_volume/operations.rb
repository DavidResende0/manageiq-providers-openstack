module ManageIQ::Providers::Openstack::StorageManager::CinderManager::CloudVolume::Operations
  extend ActiveSupport::Concern

  included do
    supports :attach do
      unsupported_reason_add(:attach, _("the volume is not connected to an active Provider")) unless ext_management_system
      unsupported_reason_add(:attach, _("the volume status is '%{status}' but should be 'available'") % {:status => status}) unless status == "available"
    end
    supports :detach do
      unsupported_reason_add(:detach, _("the volume is not connected to an active Provider")) unless ext_management_system
      unsupported_reason_add(:detach, _("the volume status is '%{status}' but should be 'in-use'") % {:status => status}) unless status == "in-use"
    end
  end

  def raw_attach_volume(server_ems_ref, device = nil)
    device = nil if device.try(:empty?)
    with_notification(:cloud_volume_attach,
                      :options => {
                        :subject =>       self,
                        :instance_name => server_ems_ref,
                      }) do
      ext_management_system.with_provider_connection(connection_options) do |service|
        service.servers.get(server_ems_ref).attach_volume(ems_ref, device)
      end
    end
  rescue => e
    volume_name = name.presence || ems_ref
    parsed_error = parse_error_message_from_fog_response(e)

    _log.error("volume=[#{volume_name}], error: #{parsed_error}")
    raise MiqException::MiqVolumeAttachError, parsed_error, e.backtrace
  end

  def raw_detach_volume(server_ems_ref)
    with_notification(:cloud_volume_detach,
                      :options => {
                        :subject =>       self,
                        :instance_name => server_ems_ref,
                      }) do
      ext_management_system.with_provider_connection(connection_options) do |service|
        service.servers.get(server_ems_ref).detach_volume(ems_ref)
      end
    end
  rescue => e
    volume_name = name.presence || ems_ref
    parsed_error = parse_error_message_from_fog_response(e)

    _log.error("volume=[#{volume_name}], error: #{parsed_error}")
    raise MiqException::MiqVolumeDetachError, parsed_error, e.backtrace
  end
end
