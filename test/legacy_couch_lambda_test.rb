require 'test_helper'

class CouchLamdaTest < Minitest::Test
  # also need a lambda to pick the customfield hash (from array with given key

  def test_web_notice_array_find
    web_notices = [{"text"=>"Anreise Freitag 17-18 Uhr, 18:30 Uhr Abendess  en, Seminarbeginn 20 Uhr",
                    "label"=>"Anreise", "field"=>"arrival"},
                   {"text"=>"Sonntag 13 Uhr Mittagessen, anschließend Abreise",
                    "label"=>"Abreise", "field"=>"departure"},
                   {"text"=>"190 € (erm. 95 €)",
                    "label"=>"Seminarkosten", "field"=>"cost_seminar"},
                   {"text"=>"Ergebnisorientiert",
                    "label"=>"Art", "field"=>"function"},
                   {"text"=>"50 €",
                    "label"=>"Biovollverpflegung", "field"=>"cost_housing"}]

    p = web_notices.find &WPEvent::CouchImport::Lambdas.web_notice_array_find('cost_housing')

    assert_equal(web_notices.last, p)

    p = web_notices.find &WPEvent::CouchImport::Lambdas.web_notice_array_find('cab', 'Art')
    assert_equal({"text"=>"Ergebnisorientiert", "label"=>"Art", "field"=>"function"}, p)
  end
end
