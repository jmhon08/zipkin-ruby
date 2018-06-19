require 'spec_helper'
module ZipkinTracer
  RSpec.describe Application do
    describe '.routable_request?' do
      subject { Application.routable_request?("path", "METHOD") }

      context 'Rails available' do
        before do
          stub_const('Rails', Class.new)
        end

        context 'route is found' do
          before do
            allow(Rails).to receive_message_chain('application.routes.recognize_path') { nil }
          end

          it 'is true' do
            expect(subject).to eq(true)
          end
        end

        context 'route is not found' do
          before do
            stub_const('ActionController::RoutingError', StandardError)
            allow(Rails).to receive_message_chain('application.routes.recognize_path').and_raise ActionController::RoutingError
          end

          it 'is false' do
            expect(subject).to eq(false)
          end
        end
      end

      context 'Rails not available' do
        it 'is true' do
          expect(subject).to eq(true)
        end
      end
    end

    describe '.get_route' do
      subject { Application.get_route("path", "METHOD") }

      context 'Rails available' do
        before do
          stub_const('Rails', Class.new)
        end

        context 'route for /api/v1/messages/in_thread/123 is found' do
          before do
            app = double('journey', to_s: "/api/v1/messages/in_thread/123")
            allow(Rails).to receive_message_chain('application.routes.router.recognize') { [[app]] }
            allow(app).to receive_message_chain('names').and_return(["thread_id", "format"])
            allow(app).to receive_message_chain('captures').and_return(["123", nil])
          end

          it 'is true' do
            expect(subject).to eq("/api/v1/messages/in_thread/:thread_id")
          end
        end

        context 'route for /api/v1/messages/in_thread/123/in_message/456 is found' do
          before do
            app = double('journey', to_s: "/api/v1/messages/in_thread/123/in_message/456")
            allow(Rails).to receive_message_chain('application.routes.router.recognize') { [[app]] }
            allow(app).to receive_message_chain('names').and_return(["thread_id", "message_id", "format"])
            allow(app).to receive_message_chain('captures').and_return(["123", "456", nil])
          end

          it 'is true' do
            expect(subject).to eq("/api/v1/messages/in_thread/:thread_id/in_message/:message_id")
          end
        end

        context 'route for /api/v1/messages is found' do
          before do
            app = double('journey', to_s: "/api/v1/messages")
            allow(Rails).to receive_message_chain('application.routes.router.recognize') { [[app]] }
            allow(app).to receive_message_chain('names').and_return(["format"])
            allow(app).to receive_message_chain('captures').and_return([nil])
          end

          it 'is true' do
            expect(subject).to eq("/api/v1/messages")
          end
        end

        context 'route is not found' do
          before do
            allow(Rails).to receive_message_chain('application.routes.router.recognize') { nil }
          end

          it 'is empty' do
            expect(subject).to eq("")
          end
        end
      end

      context 'Rails not available' do
        it 'is empty' do
          expect(subject).to eq("")
        end
      end
    end

    describe '.logger' do
      subject { Application.logger }

      context 'Rails defined' do
        before { stub_const("Rails", Class.new) }

        it 'returns rails logger' do
          expect(Rails).to receive(:logger)

          subject
        end
      end

      context 'Rails not defined' do
        it 'returns standard logger' do
          expect(Logger).to receive(:new).with(STDOUT)

          subject
        end
      end
    end

    describe '.config' do
      it 'returns empty hash if no config' do
        expect(Application.config(nil)).to eq({})
      end

      it 'returns config if available' do
        app = double('application')
        config = { config: true }
        allow(app).to receive_message_chain("config.zipkin_tracer") { config }
        expect(Application.config(app)).to eq(config)
      end
    end
  end
end
