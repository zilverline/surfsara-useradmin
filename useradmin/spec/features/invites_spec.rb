require 'feature_helper'

describe InvitesController, :feature do
  context 'invite' do
    let!(:invite) { Invite::Create.(invite: {email: 'foo@bar.com', group_id: 1, role: Role.admin}).model }

    it 'lists invites' do
      visit '/invites'
      expect(page).to have_content 'foo@bar.com'
    end

    it 'creates invites' do
      visit '/invites'
      click_on 'New invite'

      expect(page).to have_content 'New invite'

      fill_in 'Email address', with: 'user@example.com'
      select 'users', from: 'Group'
      select 'admin', from: 'Role'

      click_on 'Send invitation'

      expect(page).to have_current_path(invite_path(Invite.last.id))
      expect(page).to have_content 'Invite - user@example.com'
    end
  end

  context 'accept' do
    before { allow(InviteToken).to receive(:random).and_return(InviteToken.new(token)) }
    let(:token) { 'invite_token' }
    let!(:invite) { Invite::Create.(invite: {email: 'foo@bar.com', group_id: 1, role: Role.admin}).model }

    it 'accepts invites' do
      visit verify_invite_path(token)

      expect(page).to have_content 'Accept your invitation'

      check 'I accept the terms of service'
      click_on 'Accept'

      expect(page).to have_content 'Invite has been accepted'
      expect(page).to have_content 'Visit OpenNebula'
    end

    context 'with an already accepted invite' do
      before do
        Invite::Accept.(id: token, current_user: double(:user, uid: '123'), invite: {accept_terms_of_service: '1'})
      end

      it "can't be accepted again" do
        expect { visit verify_invite_path(token) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
