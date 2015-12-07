# EDSC-20 As a user, I want to search for collections by spatial point so that I
#         may limit my results to my point of interest

require "spec_helper"

describe "Spatial tool", reset: false do
  before :all do
    load_page :search
  end

  let(:spatial_dropdown) do
    page.find('#main-toolbar .spatial-dropdown-button')
  end

  let(:point_button)     { page.find('#map .leaflet-draw-draw-marker') }
  let(:rectangle_button) { page.find('#map .leaflet-draw-draw-rectangle') }
  let(:polygon_button)   { page.find('#map .leaflet-draw-draw-polygon') }

  context "selection" do
    context "when no tool is currently selected" do
      context "choosing the point selection tool from the site toolbar" do
        before(:each) { choose_tool_from_site_toolbar('Point') }

        it "selects the point selection tool in both toolbars" do
          expect(spatial_dropdown).to have_text('Point')
          expect(point_button).to have_class('leaflet-draw-toolbar-button-enabled')
        end
      end

      context "choosing the point selection tool from the map toolbar" do
        before(:each) { choose_tool_from_map_toolbar('Point') }

        it "selects the point selection tool in both toolbars" do
          expect(spatial_dropdown).to have_text('Point')
          expect(point_button).to have_class('leaflet-draw-toolbar-button-enabled')
        end
      end
    end
    context "when another tool is currently selected" do
      before(:each) { choose_tool_from_map_toolbar('Rectangle') }

      context "choosing the point selection tool in the site toolbar" do
        before(:each) { choose_tool_from_site_toolbar('Point') }

        it "selects the point selection tool in both toolbars" do
          expect(spatial_dropdown).to have_text('Point')
          expect(point_button).to have_class('leaflet-draw-toolbar-button-enabled')
        end
      end

      context "choosing the point selection tool in the map toolbar" do
        before(:each) { choose_tool_from_map_toolbar('Point') }

        it "selects the point selection tool in both toolbars" do
          expect(spatial_dropdown).to have_text('Point')
          expect(point_button).to have_class('leaflet-draw-toolbar-button-enabled')
        end
      end
    end

    context "choosing a tool when a point is already selected" do
      before(:each) do
        create_point
        choose_tool_from_map_toolbar('Rectangle')
      end

      it "removes the point from the map" do
        expect(page).to have_no_css('#map .leaflet-marker-icon')
      end

      context 'and clicking "Cancel"' do
        before(:each) do
          within "#map" do
            click_link "Cancel"
          end
        end

        it "adds the removed point back to the map" do
          expect(page).to have_css('#map .leaflet-marker-icon')
        end
      end
    end

    context "canceling the point selection in the toolbar" do
      before(:each) do
        choose_tool_from_map_toolbar('Point')
        within "#map" do
          click_link "Cancel"
        end
      end

      it "deselects the point selection tool in the site toolbar" do
        expect(spatial_dropdown).to have_text('Spatial')
      end
    end
  end
end

describe "Spatial" do
  before :each do
    load_page :search
  end

  context "point selection" do
    it "filters collections using the selected point" do
      create_point(0, 0)
      wait_for_xhr
      expect(page).to have_no_content("15 Minute Stream Flow Data: USGS")
      expect(page).to have_content("2000 Pilot Environmental Sustainability Index")
    end

    context "changing the point selection" do
      before(:each) do
        create_point(0, 0)
        wait_for_xhr
        create_point(-75, 40)
        wait_for_xhr
      end

      it "updates the collection filters using the new point selection" do
        expect(page).to have_content("A Global Database of Soil Respiration Data, Version 3.0")
      end
    end

    context "removing the point selection" do
      before(:each) do
        create_point(0, 0)
        wait_for_xhr
        clear_spatial
        wait_for_xhr
      end

      it "removes the spatial point collection filter" do
        expect(page).to have_content("15 Minute Stream Flow Data: USGS")
      end
    end
  end

  context "bounding box selection" do
    it "filters collections using the selected bounding box" do
      create_bounding_box(0, 0, 10, 10)
      wait_for_xhr
      expect(page).to have_no_content("15 Minute Stream Flow Data: USGS")
      expect(page).to have_content("2000 Pilot Environmental Sustainability Index")
    end

    context "changing the bounding box selection" do
      before(:each) do
        create_bounding_box(0, 0, 10, 10)
        wait_for_xhr
        create_bounding_box(-75, 40, -74, 41)
        wait_for_xhr
      end

      it "updates the collection filters using the new bounding box selection" do
        expect(page).to have_content("A Global Database of Soil Respiration Data, Version 3.0")
      end
    end

    context "removing the bounding box selection" do
      before(:each) do
        create_bounding_box(0, 0, 10, 10)
        wait_for_xhr
        clear_spatial
        wait_for_xhr
      end

      it "removes the spatial bounding box collection filter" do
        expect(page).to have_content("15 Minute Stream Flow Data: USGS")
      end
    end

    context "loading a bounding box selection over the antimeridian" do
      before :each do
        visit '/search?m=-29.25!-199.40625!0!1&sb=160%2C20%2C-170%2C40'
        wait_for_xhr
      end

      it "shows the bounding box crossing the antimeridian" do
        script = """
          (function() {
            var layers = $('#map').data('map').map._layers, key, layer, latlngs, result;
            for (key in layers) {
              if (layers[key].type == 'rectangle') {
                layer = layers[key];
                break;
              }
            }
            if (!layer) {
              result = false;
            }
            else {
              latlngs = layer.getLatLngs();
              result = latlngs[0].lng + ',' + latlngs[2].lng;
            }
            return result;
          })();
          """
          result = page.evaluate_script(script)
          expect(result).to eq("160,190")
      end
    end

    it "filters collections using north polar bounding boxes in the north polar projection" do
      click_link "North Polar Stereographic"
      create_arctic_rectangle([10, 10], [10, -10], [-10, -10], [-10, 10])
      wait_for_xhr
      expect(page).to have_no_content("15 Minute Stream Flow Data: USGS")
      expect(page).to have_content("2000 Pilot Environmental Sustainability Index")
    end

    it "filters collections using south polar bounding boxes in the south polar projection" do
      click_link "South Polar Stereographic"
      create_antarctic_rectangle([10, 10], [10, -10], [-10, -10], [-10, 10])
      wait_for_xhr
      expect(page).to have_no_content("15 Minute Stream Flow Data: USGS")
      expect(page).to have_content("2000 Pilot Environmental Sustainability Index")
    end
  end

  context "polygon selection" do
    it "filters collections using the selected polygon", intermittent: 1 do
      create_polygon([10, 10], [10, -10], [-10, -10], [-10, 10])
      wait_for_xhr
      expect(page).to have_no_content("15 Minute Stream Flow Data: USGS")
      expect(page).to have_content("2000 Pilot Environmental Sustainability Index")
    end

    it "displays errors for invalid polygons", intermittent: 1 do
      create_polygon([10, 10], [-10, -10], [10, -10], [-10, 10])
      wait_for_xhr
      expect(page).to have_content("The polygon boundary intersected itself at the following points:")
    end

    context "changing the polygon selection" do
      before(:each) do
        create_polygon([10, 10], [10, -10], [-10, -10], [-10, 10])
        wait_for_xhr
        expect(page).to have_no_content("2004 Snapshot of bird species in the Antarctic - data from World Bird Database")
        create_polygon([-87, -176], [-87, -166], [-79, -168], [-79, -179])
        wait_for_xhr
      end

      it "updates the collection filters using the new bounding box selection" do
        expect(page).to have_content("2004 Snapshot of bird species in the Antarctic - data from World Bird Database")
      end
    end

    context "removing the bounding box selection" do
      before(:each) do
        create_polygon([10, 10], [10, -10], [-10, -10], [-10, 10])
        wait_for_xhr
        clear_spatial
        wait_for_xhr
      end

      it "removes the spatial bounding box collection filter" do
        expect(page).to have_content("15 Minute Stream Flow Data: USGS")
      end
    end
  end
end
