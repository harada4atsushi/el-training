require 'rails_helper'

RSpec.describe 'Tasks', type: :system do
  context 'ログイン状態' do
    let(:current_user) { create(:user) }
    before do
      visit login_path
      fill_in 'session[email]',	with: current_user.email
      fill_in 'session[password]',	with: current_user.password
      click_button :commit
    end

    describe 'index' do
      describe 'sort' do
        it 'タスクが作成日の降順で表示される' do
          old_task = create(:task, name: '古いタスク', user: current_user)
          new_task = create(:task, name: '新しいタスク', user: current_user)
          old_task.update(name: '古いタスクを更新') # 更新しても順番が変わらないことを確認するため

          visit tasks_path
          tasks = all('.task_list')
          expect(tasks[0]).to have_content new_task.name
          expect(tasks[1]).to have_content old_task.name
        end

        it 'タスクを終了期限でソートできる' do
          slow_end_date_task = create(:task, name: '期限が遅いタスク', end_date: '2020-02-01', user: current_user)
          early_end_date_task = create(:task, name: '期限が早いタスク', end_date: '2020-01-01', user: current_user)

          visit tasks_path

          # ソートリンクを押すと初回は昇順でソートされる
          click_link Task.human_attribute_name(:end_date)
          tasks = all('.task_list')
          expect(tasks[0]).to have_content early_end_date_task.name

          # ソートリンクを押すと2回目は降順でソートされる
          click_link Task.human_attribute_name(:end_date)
          tasks = all('.task_list')
          expect(tasks[0]).to have_content slow_end_date_task.name
        end

        it 'タスクを優先順位でソートできる' do
          low_priority_task = create(:task, name: '優先順位が低いタスク', priority: 'low', user: current_user)
          high_priority_task = create(:task, name: '優先順位が高いタスク', priority: 'high', user: current_user)

          visit tasks_path

          # ソートリンクを押すと初回は昇順でソートされる
          click_link Task.human_attribute_name(:priority)
          tasks = all('.task_list')
          expect(tasks[0]).to have_content low_priority_task.name

          # ソートリンクを押すと2回目は降順でソートされる
          click_link "#{Task.human_attribute_name(:priority)} ▲"
          tasks = all('.task_list')
          expect(tasks[0]).to have_content high_priority_task.name
        end
      end

      describe 'search' do
        it 'タスク名で検索できる' do
          non_target_task = create(:task, name: '対象外のタスク', user: current_user)
          target_task = create(:task, name: '検索対象のタスク', user: current_user)

          visit tasks_path

          # 検索前はどちらも表示
          tasks = all('.task_list')
          expect(tasks[0]).to have_content target_task.name
          expect(tasks[1]).to have_content non_target_task.name

          # タスクを入��して検索
          fill_in 'q[name_cont]', with: target_task.name
          within find_by_id('task_search') do
            click_button :commit
          end

          # 検索結果に検索対象のタスクがあり、対象外はない
          tasks = all('.task_list')
          expect(tasks[0]).to have_content target_task.name
          expect(tasks[1]).not_to have_content non_target_task.name
        end

        it 'ステータスで検索できる' do
          non_target_task = create(:task, name: '対象外のタスク', user: current_user)
          target_task = create(:task, name: '検索対象のタスク', status: 'in_start', user: current_user)

          visit tasks_path

          # 検索前はどちらも表示
          tasks = all('.task_list')
          expect(tasks[0]).to have_content target_task.name
          expect(tasks[1]).to have_content non_target_task.name

          # ステータス着手中にチェックを入れ検索
          check 'q_status_in_1'
          within find_by_id('task_search') do
            click_button :commit
          end

          # 検索結果に検索対象のタスクがあり、対象外はない
          tasks = all('.task_list')
          expect(tasks[0]).to have_content target_task.name
          expect(tasks[1]).not_to have_content non_target_task.name
        end
      end

      describe 'update value' do
        it 'ステータスを変更できる' do
          target_task = create(:task, name: '対象のタスク', status: 'not_started', user: current_user)
          human_in_start = Task.human_attribute_enum_value(:status, 'in_start')

          visit tasks_path

          # 変更前は作成時のステータス
          tasks = all('.task_list')
          expect(tasks[0]).to have_content target_task.human_attribute_enum(:status)

          # ステータスを変更する
          within tasks[0] do
            within '.task-status-form' do
              select human_in_start, from: 'task_status'
              click_button :commit
            end
          end

          # ステータスが変更されている
          visit tasks_path
          tasks = all('.task_list')
          expect(tasks[0]).to have_content human_in_start
        end

        it '優先順位を変更できる' do
          target_task = create(:task, name: '対象のタスク', priority: 'low', user: current_user)
          human_middle = Task.human_attribute_enum_value(:priority, 'middle')

          visit tasks_path

          # 変更前は作成時の優先順位
          tasks = all('.task_list')
          expect(tasks[0]).to have_content target_task.human_attribute_enum(:priority)

          # 優先順位を変更する
          within tasks[0] do
            within '.task-priority-form' do
              select human_middle, from: 'task_priority'
              click_button :commit
            end
          end

          # 優先順位が変更されている
          visit tasks_path
          tasks = all('.task_list')
          expect(tasks[0]).to have_content human_middle
        end
      end
    end

    describe 'show' do
      let!(:task) { create(:task, user: current_user) }
      it 'タスクが表示される' do
        visit task_path(task)
        expect(page).to have_content task.name
      end
    end

    describe 'create' do
      it 'タスクが作成され、作成されたタスクが表示される' do
        visit new_task_path

        fill_in 'task[name]', with: 'Task name'
        fill_in 'task[description]', with: 'Task description'
        click_button :commit

        expect(page).to have_content 'タスクを作成しました。'
        expect(page).to have_content 'Task name'
        expect(page).to have_content 'Task description'
      end
      context '名前を入力していない時' do
        it 'エラーメッセージが表示される' do
          visit new_task_path

          fill_in 'task[description]', with: 'Task description'
          click_button :commit

          expect(page).to have_content 'タスク名を入力してください'
        end
      end
    end

    describe 'update' do
      let(:task) { create(:task, user: current_user) }
      let(:update_task_name) { 'Change task name' }
      it 'タスクを編集し、編集したタスクが表示される' do
        visit edit_task_path(task)

        expect(page).to have_field 'task[name]', with: task.name
        expect(page).to have_field 'task[description]', with: task.description

        fill_in 'task[name]', with: update_task_name
        click_button :commit

        expect(current_path).to eq task_path(task)
        expect(page).to have_content 'タスクを編集しました。'
        expect(page).to have_content update_task_name
        expect(page).to have_content task.description
      end
    end

    describe 'destroy', js: true do
      let(:task) { create(:task, user: current_user) }
      it 'タスクを削除する' do
        visit task_path(task)

        page.accept_confirm('タスクを削除しますか？') { click_on :task_delete }

        expect(current_path).to eq tasks_path
        expect(page).to have_content 'タスクを削除しました。'
      end
    end
  end
end
