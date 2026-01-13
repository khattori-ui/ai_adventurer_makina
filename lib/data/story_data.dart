class StoryScene {
  final String id;
  final String text;
  final String? characterImage; // キャラクター画像（オプション）
  final String? backgroundImage; // 背景画像（オプション）
  final String? characterName; // 話者の名前
  
  StoryScene({
    required this.id,
    required this.text,
    this.characterImage,
    this.backgroundImage,
    this.characterName,
  });
}

class StoryData {
  // プロローグ（初回起動時）
  static List<StoryScene> getPrologueScenes() {
    return [
      StoryScene(
        id: 'prologue_1',
        text: '帝国歴 443年 12月',
        backgroundImage: null,
      ),
      StoryScene(
        id: 'prologue_2',
        text: '王立ドキドキ南高校に通う3年生のマキナは卒業後の進路を決められずにいた。',
        characterImage: 'assets/images/makina.png',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_3',
        text: 'このまま大学に進学するのか実家のフルオートメーション農家を継ぐのか悩んでいたのである。',
        characterImage: 'assets/images/makina.png',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_4',
        text: '悩んでいる間も時は過ぎ、まわりのクラスメートが大学受験に備えている中、まだぼんやりと過ごしている自分に焦燥感が募る。',
        characterImage: 'assets/images/makina.png',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_5',
        text: '時同じくして、マキナの住む王都の隣町に冒険者ギルドの出張所が設立されることになり、冒険者の募集も始まる。',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_6',
        text: '冒険者とはギルドの依頼を受け、その成功報酬で生計を立てる者である。',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_7',
        text: '自由ではあるが実力がものをいう世界で自分を試してみたいとマキナは願った。',
        characterImage: 'assets/images/makina.png',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_8',
        text: 'あたし！冒険者になりたい！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'prologue_9',
        text: '募集チラシを手に両親に熱く語るマキナ。',
        characterImage: 'assets/images/makina.png',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_10',
        text: '両親はマキナの危険を案じ1度は引き止めたが、それでもと言い張るマキナに折れて了承する。',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_11',
        text: '翌年4月。',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_12',
        text: 'ついにマキナは王立ドキドキ南高校のジャージ姿で、母の作ったお弁当を手に冒険者ギルドの扉を叩く！',
        characterImage: 'assets/images/makina.png',
        characterName: 'ナレーション',
      ),
      StoryScene(
        id: 'prologue_13',
        text: 'よーし！今日から冒険者としての新しい人生が始まるんだ！\n頑張るぞー！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
    ];
  }
  
  // チュートリアル（プロローグ後）
  static List<StoryScene> getTutorialScenes() {
    return [
      StoryScene(
        id: 'tutorial_1',
        text: 'それでは、簡単にギルドの説明をするね。',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'tutorial_2',
        text: 'ギルドには色々な「クエスト」があって、それをこなすことで経験を積めるんだ。',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'tutorial_3',
        text: 'クエストに成功すると経験値がもらえて、レベルが上がるとステータスも強くなるよ！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'tutorial_4',
        text: 'それに、クエストをクリアすると装備品が手に入ることもあるんだって。',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'tutorial_5',
        text: 'よーし！まずは簡単なクエストから挑戦してみよう！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
    ];
  }
  
  // 初めてのクエスト成功後
  static List<StoryScene> getFirstQuestSuccessScenes() {
    return [
      StoryScene(
        id: 'first_success_1',
        text: 'やったー！初めてのクエスト、成功だよ！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'first_success_2',
        text: '冒険者として、一歩を踏み出せた気がする…！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'first_success_3',
        text: 'これからもっと色んなクエストに挑戦して、\n一人前の冒険者になるんだ！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
    ];
  }
  
  // レベル5到達時
  static List<StoryScene> getLevel5Scenes() {
    return [
      StoryScene(
        id: 'level5_1',
        text: 'レベル5になったよ！だいぶ強くなってきた気がする！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'level5_2',
        text: '最初は不安だったけど、少しずつ冒険者らしくなってきたかな？',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
    ];
  }
  
  // レベル10到達時
  static List<StoryScene> getLevel10Scenes() {
    return [
      StoryScene(
        id: 'level10_1',
        text: 'レベル10…！ついにここまで来たんだね。',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
      StoryScene(
        id: 'level10_2',
        text: '冒険者になって良かった。\nこれからも一緒に頑張ろうね！',
        characterImage: 'assets/images/makina.png',
        characterName: 'マキナ',
      ),
    ];
  }
}