require "./spec_helper"

alias Model = Policr::Model
alias Reason = Policr::ReportReason
alias ReportStatus = Policr::ReportStatus
alias UserRole = Policr::ReportUserRole
alias VoteType = Policr::VoteType

describe Policr do
  it "arabic characters match" do
    arabic_characters = /^[\x{0600}-\x{06ff}-\x{0750}-\x{077f}-\x{08A0}-\x{08ff}-\x{fb50}-\x{fdff}-\x{fe70}-\x{feff} ]+$/
    r = "گچپژیلفقهمو" =~ arabic_characters
    false.should eq(r.is_a?(Nil))
  end

  it "arabic characters count" do
    arabic_characters = /[\x{0600}-\x{06ff}-\x{0750}-\x{077f}-\x{08A0}-\x{08ff}-\x{fb50}-\x{fdff}-\x{fe70}-\x{feff}]/
    i = 0
    "العَرَبِيَّة".gsub(arabic_characters) do |_|
      i += 1
    end
    12.should eq i
  end

  it "scan" do
    Policr.scan "."
  end

  it "crud" do
    author_id = 340396281.to_i64
    post_id = 29
    target_id = 871769395.to_i64
    reason = Reason::Spam.value
    status = ReportStatus::Begin.value
    role = UserRole::Creator.value
    from_chat = -1001301664514.to_i64

    r1 = Model::Report.create({
      author_id: author_id,
      post_id:   post_id,
      target_id: target_id,
      reason:    reason,
      status:    status,
      role:      role,
      from_chat: from_chat,
    })
    r1.should be_truthy

    v1 = r1.add_votes({:author_id => author_id, :type => VoteType::Agree.value})
    v1.should be_truthy
    v2 = r1.add_votes({:author_id => author_id, :type => VoteType::Abstention.value})
    v2.should be_truthy

    v_list = Model::Vote.all.where { _report_id == r1.id }.to_a
    v_list.size.should eq(2)
    v_list.each do |v|
      r = Model::Vote.delete(v.id)
      r.should be_truthy
      if r
        r.rows_affected.should eq(1)
      end
    end

    r = Model::Report.delete(r1.id)
    r.should be_truthy
    if r
      r.rows_affected.should eq(1)
    end
  end
end
