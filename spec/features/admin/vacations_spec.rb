# frozen_string_literal: true

require 'rails_helper'

describe 'Vacation', type: :feature do
  let(:admin) { create(:user, :hr) }
  let(:commercial) { create(:user, :commercial) }
  let!(:vacation) { create(:vacation) }

  describe 'Index' do
    before do
      sign_in(admin)
      visit '/admin/vacations?scope=pending'
    end

    it 'must find fields "Usuário", "Data de início", "Data de término", "Status", "Aprovação Comercial", "Aprovação Administrativa" on table' do
      within 'table' do
        expect(page).to have_text('Usuário') &
                        have_text('Data de início') &
                        have_text('Data de término') &
                        have_text('Status')
                        have_text('Aprovação Recursos Humanos') &
                        have_text('Aprovação Comercial') &
                        have_text('Recusado Por')
      end
    end

    it 'must find correct information for vacations' do
      within 'table' do
        expect(page).to have_text(vacation.user.name) &
                        have_text(l(vacation.start_date, format: :default)) &
                        have_text(l(vacation.end_date, format: :default)) &
                        have_text(I18n.t("enumerize.vacation.status.#{vacation.status}"))
      end
    end
  end

  describe 'Filters' do
    before do
      sign_in(admin)
      visit '/admin/vacations?scope=pending'
    end

    it 'by start date' do
      within '#filters_sidebar_section' do
        expect(page).to have_text('Data de início')
      end
    end

    it 'by end date' do
      within '#filters_sidebar_section' do
        expect(page).to have_text('Data de término')
      end
    end

    it 'by end date' do
      within '#filters_sidebar_section' do
        expect(page).to have_select('Usuário')
      end
    end
  end

  describe 'Actions' do
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    describe 'Aprovar' do
      before do
        allow(VacationMailer).to receive(:notify_vacation_approved).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)

        vacation.approve!(admin)

        sign_in(commercial)
        visit '/admin/vacations?scope=pending'
      end

      it 'have vacation with hr approver' do
        within 'table' do
          find_link('Aprovar', href: "/admin/vacations/#{vacation.id}/approve").click
        end

        within 'td.col-hr_approver' do
          expect(page).to have_text(admin.name)
        end
      end

      it 'have vacation with project manager approver' do
        within 'table' do
          find_link('Aprovar', href: "/admin/vacations/#{vacation.id}/approve").click
        end

        within 'td.col-commercial_approver' do
          expect(page).to have_text(commercial.name)
        end
      end

      it 'have status approved' do
        within 'table' do
          find_link('Aprovar', href: "/admin/vacations/#{vacation.id}/approve").click
        end

        within 'td.col-status' do
          expect(page).to have_text(Vacation.status.approved.text)
        end
      end

      it 'Sends an email to the user' do
        expect(VacationMailer).to receive(:notify_vacation_approved)

        within 'table' do
          find_link('Aprovar', href: "/admin/vacations/#{vacation.id}/approve").click
        end
      end
    end

    describe 'Recusar' do
      let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

      before do
        allow(VacationMailer).to receive(:notify_vacation_denied).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_later)

        sign_in(admin)
        visit '/admin/vacations?scope=all'
      end

      it 'have vacation with administrative approver' do
        within 'table' do
          find_link('Recusar', href: "/admin/vacations/#{vacation.id}/denied").click
        end

        visit '/admin/vacations?scope=denied'

        within 'td.col-denier' do
          expect(page).to have_text(admin.name)
        end
      end

      it 'have status denied' do
        within 'table' do
          find_link('Recusar', href: "/admin/vacations/#{vacation.id}/denied").click
        end

        visit '/admin/vacations?scope=denied'

        within 'td.col-status' do
          expect(page).to have_text(Vacation.status.denied.text)
        end
      end

      it 'Sends an email to the user' do
        expect(VacationMailer).to receive(:notify_vacation_denied)

        within 'table' do
          find_link('Recusar', href: "/admin/vacations/#{vacation.id}/denied").click
        end
      end
    end
  end
end
