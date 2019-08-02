# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      class RevenueShares < Grape::API

        desc 'Returns revenues sharing as paginated collection.' do
          @settings[:scope] = :read_revenue_shares
          success API::V2::Management::Entities::RevenueShare
        end
        params do
          optional :member_uid, type: String, desc: 'The member unique identifier to filter by.'
          optional :parent_uid, type: String, desc: 'The parent unique identifier to filter by.'
          optional :state,      type: String, desc: 'The state to filter by.',  values: -> { RevenueShare::STATES }
        end
        post '/revenue-shares' do
          member = Member.find_by!(uid: params[:member_uid]) if params[:member_uid].present?
          parent = Member.find_by!(uid: params[:parent_uid]) if params[:parent_uid].present?

          ::RevenueShare.order(id: :asc)
              .tap { |q| q.where!(member: member) if member }
              .tap { |q| q.where!(parent: parent) if parent }
              .tap { |q| q.where!(state: params[:state]) if params[:state] }
              .includes(:member, :parent)
              .page(params[:page])
              .per(params[:limit])
              .tap { |q| present q, with: API::V2::Management::Entities::RevenueShare }
          status 200
        end

        desc 'Returns revenue share by unique identifier.' do
          @settings[:scope] = :read_revenue_shares
          success API::V2::Management::Entities::RevenueShare
        end
        params do
          requires :id, type: Integer, desc: 'The revenue share unique identifier.'
        end
        post '/revenue-shares/get' do
          present RevenueShare.find_by!(params.slice(:id)), with: API::V2::Management::Entities::RevenueShare
        end


        desc 'Creates new revenue share with state set to «disabled».' do
          @settings[:scope] = :write_revenue_shares
          success API::V2::Management::Entities::RevenueShare
        end
        params do
          requires :member_uid, type: String,     desc: 'The member unique identifier.'
          requires :parent_uid, type: String,     desc: 'The parent unique identifier.'
          requires :percent,    type: BigDecimal, desc: 'The percent to be attached.'
          optional :state,      type: String,     desc: 'The state of revenue share.', values: -> { RevenueShare::STATES }
        end
        post '/revenue-shares/new' do
          member = Member.find_by(uid: params[:member_uid])
          parent = Member.find_by(uid: params[:parent_uid])

          data          = { member: member, parent: parent }
          revenue_share = ::RevenueShare.new(data).tap do |rs|
            rs.percent = params[:percent]
            rs.state   = params[:state] if params[:state].present?
          end

          if revenue_share.save
            present revenue_share, with: API::V2::Management::Entities::RevenueShare
          else
            body errors: revenue_share.errors.full_messages
            status 422
          end
        end

        desc 'Updates state/percent of revenue share.' do
          @settings[:scope] = :write_revenue_shares
          success API::V2::Management::Entities::RevenueShare
        end
        params do
          requires :id,      type: Integer,    desc: 'The revenue share unique identifier.'
          optional :state,   type: String,     desc: 'The new state to apply.', values: -> { RevenueShare::STATES }
          optional :percent, type: BigDecimal, desc: 'The new percent to apply.'
        end
        put '/revenue-shares/update' do
          revenue_share = ::RevenueShare.find_by!(params.slice(:id)).tap do |rs|
            rs.state = params[:state] if params[:state].present?
            rs.percent = params[:percent] if params[:percent].present?
          end

          if revenue_share.save
            present revenue_share, with: API::V2::Management::Entities::RevenueShare
          else
            body errors: revenue_share.errors.full_messages
            status 422
          end
        end
      end
    end
  end
end
