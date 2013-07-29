require 'rspec'

class Game

  def initialize
    @rolls = 0
    @frames = []
  end

  def roll pins
    raise if invalid_pins? pins
    raise if game_is_over?

    add_roll pins
  end

  def frames
    @frames
  end

  def score
    score = 0

    frames.each_with_index do |frame, index|
      frame_score = frame.rolls_sum
      if frame.spare? || frame.strike?
        frame_score += frames[index + 1].rolls_sum
      end

      score += frame_score
    end

    score
  end

  private

  def add_roll pins
    if frames.empty? || frames.last.complete?
      frames << Frame.new
    end

    frames.last.add_roll pins

    @rolls += 1
  end

  def invalid_pins? pins
    pins > 10 || pins < 0
  end

  def game_is_over?
    @rolls > 19
  end
end

class Frame
  def initialize
    @rolls = []
    @strike = false
  end

  def add_roll roll
    raise 'Invalid rolls sum' if invalid_rolls_sum? roll
    raise 'No more rolls allowed'if rolls_limit?
    raise 'Frame complete due strike' if strike?

    @strike = roll == 10
    @rolls << roll
  end

  def rolls
    @rolls
  end

  def strike?
    @strike
  end

  def spare?
    rolls_sum == 10
  end

  def complete?
    rolls.count == 2 ||
      strike?
  end

  def rolls_sum
    rolls.reduce(0) { |sum, roll| sum += roll; sum }
  end

  private
  def rolls_limit?
    @rolls.count == 2
  end

  def invalid_rolls_sum? roll
     rolls_sum + roll > 10
  end
end

describe Game do
  it 'rolls' do
    subject.roll 9
  end

  it 'does not allow invalid rolls' do
    expect{subject.roll(11)}.to raise_error
    expect{subject.roll(-1)}.to raise_error
  end

  it 'only allows 20 rolls' do
    expect { 20.times { subject.roll 5 } }.not_to raise_error
    expect { subject.roll 9 }.to raise_error
  end

  describe 'keeping track of frames' do
    it 'keeps track on incomplete games' do
      3.times do
        subject.roll 4
      end

      expect(subject.frames.count).to eq(2)
    end

    it 'keeps track on full games' do
      20.times do
        subject.roll 4
      end

      expect(subject.frames.count).to eq(10)
    end

    it 'keeps track on games with strikes' do
      subject.roll 0
      subject.roll 10
      subject.roll 10
      subject.roll 10
      subject.roll 4
      subject.roll 4
      subject.roll 10

      expect(subject.frames.count).to eq(5)
    end

    it 'fails when adding invalid rolls' do
      subject.roll 10
      subject.roll 4
      expect { subject.roll(10) }.to raise_error
    end

  end

  describe 'keeping score' do
    it 'should know score without spares on incomplete game' do
      3.times do
        subject.roll 4
      end

      expect(subject.score).to eq(12)
    end

    it 'should know score without spares on complete game' do
      20.times do
        subject.roll 4
      end

      expect(subject.score).to eq(80)
    end

    it 'should know score with spares 1 on incomplete game' do
      subject.roll 4
      subject.roll 6
      subject.roll 5

      expect(subject.score).to eq(20)
    end

    it 'should know score with spares 2 on incomplete game' do
      subject.roll 0
      subject.roll 10
      subject.roll 5

      expect(subject.score).to eq(20)
    end

    it 'should know score with strikes on incomplete game' do
      subject.roll 10
      subject.roll 5
      subject.roll 2

      expect(subject.score).to eq(24)
    end

    it 'should know score with strikes and spares on incomplete game' do
      subject.roll 10
      subject.roll 5
      subject.roll 5
      subject.roll 3

      expect(subject.score).to eq(36)
    end


  end
end

describe Frame do
  it 'adds_rolls' do
    subject.add_roll 5
  end

  it 'knows the rolls sum' do
    expect(subject.rolls_sum).to eq(0)
    subject.add_roll 5
    expect(subject.rolls_sum).to eq(5)
  end

  describe 'base rules' do
    it 'keeps track of each roll' do
      subject.add_roll 5
      subject.add_roll 2
      expect(subject.rolls.first).to eq(5)
      expect(subject.rolls.last).to eq(2)
    end

    it 'only allows two rolls' do
      subject.add_roll 5
      subject.add_roll 4
      expect { subject.add_roll 4 }.to raise_error
    end

    it 'only allows two rolls' do
      subject.add_roll 5
      subject.add_roll 1
      expect { subject.add_roll 4 }.to raise_error
    end

    it 'knows when frame is complete' do
      subject.add_roll 1
      expect(subject.complete?).to be_false
      subject.add_roll 1
      expect(subject.complete?).to be_true
    end

    it 'does not allow invalid score sums' do
      subject.add_roll 5
      expect { subject.add_roll(10) }.to raise_error
    end
  end

  describe 'spare rules' do
    it 'knows when the roll was a spare' do
      subject.add_roll 9
      subject.add_roll 1
      expect(subject.spare?).to be_true
    end

    it 'knows when the roll was not a spare' do
      subject.add_roll 3
      subject.add_roll 1
      expect(subject.spare?).not_to be_true
    end

    it 'knows when frame is complete' do
      subject.add_roll 5
      expect(subject.complete?).to be_false
      subject.add_roll 5
      expect(subject.complete?).to be_true
    end
  end

  describe 'strike rules' do
    it 'only allows 1 roll' do
      subject.add_roll 10
      expect { subject.add_roll 4 }.to raise_error
    end

    it 'allows strike on second roll' do
      subject.add_roll 0
      subject.add_roll 10
      expect(subject.strike?).to be_true
      expect { subject.add_roll 4 }.to raise_error
    end

    it 'knows when the roll was not a strike' do
      subject.add_roll 1
      expect(subject.strike?).to be_false
    end

    it 'knows when frame is complete' do
      subject.add_roll 10
      expect(subject.complete?).to be_true
    end
  end

end
