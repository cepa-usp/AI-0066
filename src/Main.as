/*
 * Changelog
 * ----------------------
 * 2011.01.06: correção de bug (Ivan)
 * Sintomas: em algumas ocasiões, a AI deixa de lançar o alvo para cima (e, por conseguinte, de atirar); o revólver ainda segue o mouse.
 * Diagnóstico: o problema ocorre quando a bala NÃO acerta o alvo. Neste caso a animação termina com a bala FORA do palco (condição para identificar o fim da animação nesses casos) e, ao começar uma nova animação, o software imediatamente identifica que animação terminou, pois a bala está fora do palco.
 * Solução: sempre que terminar a animação, reposicionar a bala na sua posição original (igual à do revólver) e ocultá-la.
 * ----------------------
 */
package 
{
	import BaseAssets.BaseMain;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuBuiltInItems;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	import pipwerks.SCORM;

	import cepa.utils.Cronometer;
	
	public class Main extends BaseMain
	{
		//--------------------------------------------------
		// Membros públicos (interface).
		//--------------------------------------------------
		
		/**
		 * Cria um novo objeto desta classe.
		 */
		public function Main ()
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		/**
		 * Restaura a CONFIGURAÇÃO inicial (padrão).
		 */
		override public function reset(e:MouseEvent = null):void
		{
			// Reposiciona o alvo
			target.x = TARGET_R0_PIXELS.x;
			target.y = TARGET_R0_PIXELS.y;
			
			// Reposiciona a bala
			bullet.x = BULLET_R0_PIXELS.x;
			bullet.y = BULLET_R0_PIXELS.y;
			bullet.visible = false;
			
			updatePerfectAimAngle();
			
			// Reposiciona a arma
			gun.x = bullet.x;
			gun.y = bullet.y;
			gun.rotation = 0;
			
			// Zera a contagem de tempo da animação do alvo
			tTarget.reset();
			tTarget.stop();
			
			// Zera a contagem de tempo da animação da bala
			tBullet.reset();
			tBullet.stop();
			
			// Estado inicial
			state = STATE_1;
			
			// Instrução inicial
			info.text = "Clique para jogar o alvo ou arraste o revólver"
			
			// Oculta a marca da bala no alvo
			target.hole.visible = false;
		}
		
		/**
		 * Mapeia um <code>Point r</code> no <code>Rectangle from</code> para um ponto no <code>Rectangle to</code>.
		 * @param	r O ponto a ser mapeado (em coordenadas de <code>from</code>)
		 * @param	from O retângulo de origem
		 * @param	to O retângulo de destino
		 * @return  O ponto mapeado (em coordenadas de <code>to</code>)
		 */
		public static function map (r:Point, from:Rectangle, to:Rectangle) : Point
		{
			return new Point(
				to.left + to.width / from.width * (r.x - from.left),
				to.top - to.height / from.height * (r.y - from.top)
			);
		}
		
		//--------------------------------------------------
		// Membros privados.
		//--------------------------------------------------
		private const STATE_1:String = "STATE_1"; // Antes de jogar o alvo (início)
		private const STATE_2:String = "STATE_2"; // Após jogar o alvo e antes de atirar (com o revólver)
		private const STATE_3:String = "STATE_3"; // Após atirar e antes de encerrar a animação
		private const STATE_4:String = "STATE_4"; // Após encerrar a animação (fim)
		private const VIEWPORT:Rectangle = new Rectangle(0, 0, 700, 500); // Área visível do palco
		private const GUN_AREA:Rectangle = new Rectangle(60, 40, VIEWPORT.width / 2 - 60, VIEWPORT.height - 40 - 50);
		private const SCENE:Rectangle = new Rectangle(0, 30, 50, 30); // Área da cena correspondente à do palco
		private const G = new Point(0, -2); // Aceleração da gravidade (m/s/s)
		private const TARGET_R0:Point = new Point(44, 5); // Posição inicial do alvo (em metros)
		private const TARGET_R0_PIXELS:Point = meter2pixel(TARGET_R0); // Posição inicial do alvo (em pixels)
		private const BULLET_R0:Point = new Point(5, 5); // Posição inicial da bala do revólver (em metros)
		private const BULLET_R0_PIXELS:Point = meter2pixel(BULLET_R0); // Posição inicial da bala do revólve (em pixels)
		private const H_MAX:Number = 0.85 * (SCENE.top - TARGET_R0.y); // Altura máxima atingida pelo alvo (configurada de modo que nunca saia da área visível do palco)
		private const TARGET_V0:Point = new Point(0, Math.sqrt(2 * H_MAX * Math.abs(G.y))); // Velocidade inicial do alvo (ao ser jogado para cima, na vertical) (em m/s)
		private const BULLET_SPEED:Number = 1.5 * TARGET_V0.y; // Módulo da velocidade da bala (m/s)
		private const GUNFIRE_URI:String = "assets/sound/gunfire.mp3"; // URI do efeito sonoro do tiro
		private const gunfireTransform:SoundTransform = new SoundTransform(1, -0.5); // Faz o som do tiro ser mais intenso na caixa esquerda
		private const TARGET_HIT_URI:String = "assets/sound/target_hit.mp3"; // URI do efeito sonoro da bala atingindo o alvo
		private const TARGET_HIT_TRANSFORM:SoundTransform = new SoundTransform(1, +0.5); // Faz o som do tiro ser mais intenso na caixa esquerda		
		private const N:int = 3; // Número de vezes SEGUIDAS que o usuário deve acertar o alvo para poder ter acesso à questão 2
		
		private var t:Number; // Instante de tempo
		private var target:Target; // O alvo
		private var bullet:Sprite; // A bala
		private var state:String; // Estado da AI
		private var tTarget:Cronometer; // Cronômetro usado para gerenciar o tempo da animação do alvo
		private var tBullet:Cronometer; // Cronômetro usado para gerenciar o tempo da animação da bala
		private var bullet_v0:Point; // Velocidade inicial da bala (em m/s)
		private var stageAimAngle:Number; // Ângulo atual de tiro, no sistema de coordenadas do palco (usado para rotacionar a arma)
		private var sceneAimAngle:Number; // Ângulo atual de tiro, no sistema de coordenadas da cena (usado nas equações de movimento)
		private var gunfire:Sound; // Som do tiro
		private var targethit:Sound; // Som da bala atingindo o alvo
		private var streak:int; // Número de acertos seguidos
		private var draggingGun:Boolean; // Indica se a arma está sendo arrastada ou não
		private var perfectStageAimAngle:Number = -Math.atan((H_MAX * VIEWPORT.height / SCENE.height) / (TARGET_R0_PIXELS.x - BULLET_R0_PIXELS.x)); // Ângulo perfeito de tiro, no sistema de coordenadas do palco (usado para alinhar rotacionar a arma)
		private var perfectSceneAimAngle:Number = -Math.atan(H_MAX / (TARGET_R0.x - BULLET_R0.x)); // Ângulo perfeito de tiro, no sistema de coordenadas da cena (usado nas equações de movimento)		
		private var bullet_r0:Point; // Posição inicial da bala
		private var clickOffset:Point;
		private var challengeAchieved:Boolean;
		private var shots:Array;
		
		/*
		 * Inicialização (CRIAÇÃO DE OBJETOS) dependente do palco (stage).
		 */
		private function init (event:Event = null) : void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			nuvens.mouseChildren = false;
			// Configura o alvo
			target = new Target();
			addChild(target);
			
			tTarget = new Cronometer();
			
			// Configura a bala
			bullet = new Bullet();
			addChild(bullet);
			
			tBullet = new Cronometer();
			
			bullet_r0 = BULLET_R0;
			bullet_v0 = new Point();
			
			streak = 0;
			shots = new Array();
			
			clickOffset = new Point();
			
			challengeAchieved = false;
			
			// Som do tiro
			gunfire = new Sound();
			gunfire.load(new URLRequest(GUNFIRE_URI));
			
			// Som da bala atingindo o alvo
			targethit = new Sound();
			targethit.load(new URLRequest(TARGET_HIT_URI));
			
			// Configura a arma
			gun.x = BULLET_R0_PIXELS.x;
			gun.y = BULLET_R0_PIXELS.y;
			gun.aim = false;
			setChildIndex(gun, 0);
			gun.addEventListener(MouseEvent.MOUSE_DOWN, grabGun);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragGun);
			stage.addEventListener(MouseEvent.MOUSE_UP, releaseGun);
			
			setChildIndex(bullet, 0);
			setChildIndex(target, 0);
			setChildIndex(nuvens, 0);
			
			// Ativa a interação com o mouse
			stage.addEventListener(MouseEvent.CLICK, interact);
			
			//modeSelector.visible = false;
			hideModeScreen();
			modeBar.addEventListener(MouseEvent.CLICK, showModeScreen);
			modeSelector.addEventListener(Event.CHANGE, changeMode);
			
			feedbackScreen.addEventListener("OK", changeMode);
			
			initContextMenu();
			reset();
			
			gun.buttonMode = true;
			
			if (ExternalInterface.available) {
				initLMSConnection();
				if (!completed) iniciaTutorial();
				else {
					modeBar.mouseEnabled = false;
					modeBar.alpha = 0.5;
					modeBar.filters = [GRAYSCALE_FILTER];
				}
			}else{
				iniciaTutorial();
			}
		}
		
		private function changeMode(e:Event):void 
		{
			if(ModeBar(modeBar).mode == ModeSelector.MODE_EVAL){
				modeBar.swap();
				streak = 0;
				modeSelector.selectInv(null);
				gun.buttonMode = true;
			}else {
				modeBar.swap();
				streak = 0;
				modeSelector.selectEval(null);
				gun.buttonMode = false;
			}
			
			resetAnimation();
		}
		
		private function showModeScreen (event:MouseEvent) : void 
		{
			modeSelector.visible = true;
			setChildIndex(modeSelector, numChildren - 1);
		}
		
		/*
		 * Oculta a tela de seleção de modo
		 */
		private function hideModeScreen (event:Event = null) : void
		{
			modeSelector.visible = false;
		}
		
		/*
		 * Cria o menu de contexto, com o item "sobre" (créditos).
		 */
		private function initContextMenu () : void
		{
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
            var defaultItems:ContextMenuBuiltInItems = menu.builtInItems;
            defaultItems.print = true;
			
			var item:ContextMenuItem = new ContextMenuItem("Sobre...");
            menu.customItems.push(item);
            item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, openCreditosContext);
			contextMenu = menu;
		}
		
		/**
		 * Restaura a CONFIGURAÇÃO inicial (padrão).
		 */
		public function resetAnimation ()
		{
			if (modeBar.mode == ModeSelector.MODE_EVAL)
			{
				bullet.x = gun.x = GUN_AREA.left + GUN_AREA.width * Math.random();
				bullet.y = gun.y = GUN_AREA.top + GUN_AREA.height * Math.random();
			}else {
				bullet.x = gun.x;
				bullet.y = gun.y;
			}
			
			updatePerfectAimAngle();
			
			// Reposiciona arma
			gun.rotation = 0;
			
			// Reposiciona o alvo
			target.x = TARGET_R0_PIXELS.x;
			target.y = TARGET_R0_PIXELS.y;
			
			// Zera a contagem de tempo da animação do alvo
			tTarget.reset();
			tTarget.stop();
			
			// Zera a contagem de tempo da animação da bala
			tBullet.reset();
			tBullet.stop();
			
			// Estado inicial
			state = STATE_1;
			
			// Instrução inicial
			info.text = "Clique para jogar o alvo" + (modeBar.mode == ModeSelector.MODE_EXPLORE ? " ou arraste o revólver" : "");
			
			// Oculta a marca da bala no alvo
			target.hole.visible = false;
			
			// Oculta a bala
			bullet.visible = false;
			
		}
		
		/*
		 * Controla as ações de (1) lançar o alvo, (2) atirar, (3) parar a animação e (4) recomeçar
		 */
		private function interact (event:MouseEvent) : void
		{
			if (event.target == stage || event.target == target || event.target == gun.laser || event.target == nuvens) switch (state)
			{
				// Estado inicial: antes de jogar o alvo e de atirar
				case STATE_1:
					throwTarget();
					break;
				
				// Após soltar o alvo
				case STATE_2:
					fire();
					break;
					
				// Durante a animação do tiro
				case STATE_3:
					resetAnimation();
					break;
				
				// Após acabar a animação (atingir o alvo ou terminar a animação)
				case STATE_4:
					resetAnimation();
					break;
				
				default:
					break;
			}
		}
		
		/*
		 * Pega a arma (começa a arrastá-la).
		 */
		private function grabGun (event:MouseEvent) : void
		{
			if (state == STATE_1 && !draggingGun && modeBar.mode == ModeSelector.MODE_EXPLORE)
			{
				draggingGun = true;
				clickOffset.x = event.localX;
				clickOffset.y = event.localY;
			}
		}
		
		/*
		 * Move a arma.
		 */
		private function dragGun (event:MouseEvent) : void
		{
			if (draggingGun)
			{
				bullet.x = gun.x = Math.max(60, Math.min(mouseX - clickOffset.x, VIEWPORT.left + 1/2 * VIEWPORT.width));
				bullet.y = gun.y = Math.max(40, Math.min(mouseY - clickOffset.y, VIEWPORT.bottom - 50));
				
				updatePerfectAimAngle();
				
				event.updateAfterEvent();
			}
		}
		
		/*
		 * Solta a arma.
		 */
		private function releaseGun (event:MouseEvent) : void
		{
			if (draggingGun)
			{
				draggingGun = false;
			}
		}
		
		/*
		 * Recalcula o ângulo correto de tiro.
		 */
		private function updatePerfectAimAngle () : void
		{
			bullet_r0 = pixel2meter(new Point(bullet.x, bullet.y));
			
			perfectStageAimAngle = Math.atan((TARGET_R0_PIXELS.y - H_MAX * VIEWPORT.height / SCENE.height - bullet.y) / (TARGET_R0_PIXELS.x - bullet.x)); // Ângulo perfeito de tiro, no sistema de coordenadas do palco (usado para alinhar rotacionar a arma)
			perfectSceneAimAngle = Math.atan((TARGET_R0.y + H_MAX - bullet_r0.y) / (TARGET_R0.x - bullet_r0.x)); // Ângulo perfeito de tiro, no sistema de coordenadas da cena (usado nas equações de movimento)
		}
		
		/*
		 * Joga o alvo.
		 */
		private function throwTarget () : void
		{
			if (state == STATE_1)
			{
				state = STATE_2;
				tTarget.start();
				
				info.text = "Clique para atirar";
				
				if (!hasEventListener(Event.ENTER_FRAME)) addEventListener(Event.ENTER_FRAME, update);
				
				aim();
				stage.addEventListener(MouseEvent.MOUSE_MOVE, aim);
				gun.aim = true;
			}
		}
		
		/*
		 * Atira o projétil.
		 */
		private function fire () : void
		{
			if (state == STATE_2)
			{
				gun.play();
				bullet.visible = true;
				
				// t0
				tBullet.start();
				
				// r0
				bullet.x = gun.x;
				bullet.y = gun.y;
				bullet_r0 = pixel2meter(new Point(bullet.x, bullet.y));
				
				// v0
				bullet_v0.x = BULLET_SPEED * Math.cos(sceneAimAngle);
				bullet_v0.y = BULLET_SPEED * Math.sin(sceneAimAngle);
				
				info.text = "Clique para recomeçar";
				
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, aim);
				gun.aim = false;
				
				gunfireTransform.pan = -1 + 2 / stage.stageWidth * gun.x;
				if (gunfire.bytesLoaded == gunfire.bytesTotal) gunfire.play(0, 1, gunfireTransform);
				
				state = STATE_3;
				
			}
		}
		
		/*
		 * Finaliza a animação.
		 */
		private function finishAnimation () : void
		{
			if (state == STATE_2 || state == STATE_3)
			{
				state = STATE_4;
				info.text = "Clique para recomeçar";
				
				tTarget.stop();
				tBullet.stop();
				
				bullet.x = gun.x;
				bullet.y = gun.y;
				bullet.visible = false;
				
				if (hasEventListener(Event.ENTER_FRAME)) removeEventListener(Event.ENTER_FRAME, update);
			}
		}
		
		/*
		 * Mira o revólver (acompanha o mouse)
		 */
		private function aim (event:Event = null) : void
		{
			// O ângulo perfeito de tiro, no sistema de referência do palco
			stageAimAngle = Math.atan2(mouseY - gun.y, mouseX - gun.x);
			if (Math.abs(stageAimAngle - perfectStageAimAngle) < 2 * Math.PI / 180) stageAimAngle = perfectStageAimAngle;
			gun.rotation = stageAimAngle * 180 / Math.PI;
			
			// O ângulo perfeito de tiro, no sistema de referência da cena (usado nas equações de movimento)
			var mousePos:Point = pixel2meter(new Point(mouseX, mouseY));
			var gunPos:Point = pixel2meter(new Point(gun.x, gun.y));
			sceneAimAngle = Math.atan2(mousePos.y - gunPos.y, mousePos.x - gunPos.x);
			if (Math.abs(sceneAimAngle - perfectSceneAimAngle) < 2 * Math.PI / 180) sceneAimAngle = perfectSceneAimAngle;
		}
		
		/*
		 * Atualiza a posição da bala.
		 */
		private function update (event:Event) : void
		{
			var position:Point;
			var velocity:Point;
			
			// Atualiza a posição do alvo
			if (state == STATE_2 || state == STATE_3)
			{
				t = tTarget.read() / 1000;
				
				position = meter2pixel(r(TARGET_R0, TARGET_V0, G, t));
				target.x = position.x;
				target.y = position.y;
			}
			
			// Atualiza a posição da bala
			if (state == STATE_3)
			{
				t = tBullet.read() / 1000;
				
				position = meter2pixel(r(bullet_r0, bullet_v0, G, t));
				bullet.x = position.x;
				bullet.y = position.y;
				
				velocity = v(bullet_v0, G, t);
				velocity.x *= VIEWPORT.width / SCENE.width;
				velocity.y *= -VIEWPORT.height / SCENE.height;
				bullet.rotation = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
			}
			
			if (!VIEWPORT.contains(bullet.x, bullet.y))
			{
				finishAnimation();
				streak = 0;
				wrongShot();
			}
			else if (!VIEWPORT.contains(target.x, target.y))
			{
				finishAnimation();
				streak = 0;
				wrongShot();
			}
			else if (bullet.x > target.x)
			{
				// Acertou o alvo
				if (Math.abs(bullet.y - target.y) < target.width / 2)
				{
					if (targethit.bytesLoaded == targethit.bytesTotal) targethit.play(0, 1, TARGET_HIT_TRANSFORM);
					
					shots.push(true);
					
					target.hole.visible = true;
					target.hole.y = bullet.y - target.y;
					
					
					bullet.visible = false;
					bullet.x = gun.x;
					bullet.y = gun.y;
					
					if (modeBar.mode == ModeSelector.MODE_EVAL && !challengeAchieved)
					{
						if (++streak == N)
						{
							challengeAchieved = true;
							feedbackScreen.okCancelMode = false;
							feedbackScreen.setText("Parabéns! Parece que você já entendeu qual é a técnica, o que conclui esta atividade interativa. Entretanto, você pode continuar atirando quantas vezes quiser.");
							
							//Colocar completed = true e impedir que o status seja modificado.
							
							if(ExternalInterface.available){
								if (!completed) {
									completed = true;
									score = 100;
									
									commit();
								}
							}
							
							changeMode(null);
							modeBar.mouseEnabled = false;
							modeBar.alpha = 0.5;
							modeBar.filters = [GRAYSCALE_FILTER];
						}
					}
					
					finishAnimation();
				}
			}
		}
		
		private function wrongShot():void
		{
			if (modeBar.mode == ModeSelector.MODE_EVAL && !challengeAchieved) {
				shots.push(false);
				verifyWrongShots();
			}
			//TODO: contabilizar os erros, caso o aluno erre 3 em 5 mostrar a seguinte mensagem:
			//"Parece que você não identificou a técnica para acertar o alvo. Você gostaria de voltar para o modo de investigação (nele, você pode posicionar a arma livremente)?"
			
		}
		
		private function verifyWrongShots():void
		{
			if (shots.length >= 5) {
				var wrongShots:int = 0;
				for (var i:int = shots.length - 1; i >= shots.length - 5 ; i--)
				{
					if (!shots[i]) wrongShots++;
				}
				
				if (wrongShots >= 3) {
					feedbackScreen.okCancelMode = true;
					feedbackScreen.setText("Parece que você não identificou a técnica para acertar o alvo. Você gostaria de voltar para o modo de investigação (nele, você pode posicionar a arma livremente)?");
					//A tela de mensagem deve conter 2 botões: OK e CANCELAR, onde OK volta para o modo de experimentação e CANCELAR permanesse no modo avaliação.
				}
			}
		}
		
		/*
		 * Retorna a posição r no instante t, para r0 (posição inicial), v0 (velocidade inicial) e a (aceleração constante).
		 */
		private function r (r0:Point, v0:Point, a:Point, t:Number) : Point
		{
			return new Point(
				r0.x + v0.x * t + a.x * t * t / 2,
				r0.y + v0.y * t + a.y * t * t / 2
			);
		}
		
		/*
		 * Retorna a posição r no instante t, para r0 (posição inicial), v0 (velocidade inicial) e a (aceleração constante).
		 */
		private function v (v0:Point, a:Point, t:Number) : Point
		{
			return new Point(
				v0.x + a.x * t,
				v0.y + a.y * t
			);
		}
		
		/*
		 * Mapeia posições na cena (em metros) para o viewport (em pixels).
		 */
		private function meter2pixel (r:Point) : Point
		{
			return Main.map(r, SCENE, VIEWPORT);
		}
		
		/*
		 * Mapeia posições no viewport (em pixels) para a cena (em metros).
		 */
		private function pixel2meter (r:Point) : Point
		{
			return Main.map(r, VIEWPORT, SCENE);
		}
		
		
		//---------------- Tutorial -----------------------
		
		private var balao:CaixaTexto;
		private var gunPos:Point = new Point();
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var alturaForTuto:Point = new Point();
		private var etoForTuto:Point = new Point();
		private var tutoSequence:Array = ["O primeiro clique do mouse em qualquer lugar do cenário (exceto no revólver) lança o alvo para cima.", 
										  "O segundo clique faz o revólver atirar.",
										  "O terceiro clique começa uma nova tentativa.",
										  "A mira do revólver (linha tracejada) sempre segue o mouse.",
										  "No modo de investigação você pode mover o revólver livremente.",
										  "Quando você achar que já está preparado(a) para ser avaliado(a), alterne para o modo de avaliação."];
		
		override public function iniciaTutorial(e:MouseEvent = null):void 
		{
			tutoPos = 0;
			gunPos.x = gun.x;
			gunPos.y = gun.y;
			
			if(balao == null){
				balao = new CaixaTexto(true);
				addChild(balao);
				balao.visible = false;
				
				pointsTuto = 	[new Point(target.x - target.width / 2, target.y),
								gunPos,
								new Point(180, 200),
								gunPos,
								gunPos,
								new Point(modeBar.x + modeBar.width / 2, modeBar.y + modeBar.height)];
								
				tutoBaloonPos = [[CaixaTexto.RIGHT, CaixaTexto.LAST],
								["as", "as"],
								["", ""],
								[CaixaTexto.LEFT, CaixaTexto.FIRST],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.TOP, CaixaTexto.LAST]];
			}
			balao.removeEventListener(Event.CLOSE, closeBalao);
			
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(Event.CLOSE, closeBalao);
			balao.visible = true;
		}
		
		private function updateGunPos():void
		{
			gunPos.x = gun.x;
			gunPos.y = gun.y;
			
			if (tutoPos == 1) {
				if (gun.y > 150) tutoBaloonPos[1][0] = CaixaTexto.BOTTON;
				else tutoBaloonPos[1][0] = CaixaTexto.TOP;
				
				if (gun.x > 100) tutoBaloonPos[1][1] = CaixaTexto.CENTER;
				else tutoBaloonPos[1][1] = CaixaTexto.FIRST;
			}else {
				gunPos.x += 35;
			}
		}
		
		private function closeBalao(e:Event):void 
		{
			tutoPos++;
			updateGunPos();
			if (tutoPos >= tutoSequence.length) {
				balao.removeEventListener(Event.CLOSE, closeBalao);
				balao.visible = false;
			}else {
				balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
				balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			}
		}
		
		
		
		/*------------------------------------------------------------------------------------------------*/
		//SCORM:
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormExercise:int;
		private var connected:Boolean;
		private var score:int = 0;
		private var pingTimer:Timer;
		private var mementoSerialized:String = "";
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			pingTimer = new Timer(PING_INTERVAL);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			
			connected = scorm.connect();
			
			if (connected) {
				
				if (scorm.get("cmi.mode") != "normal") return;
				
				scorm.set("cmi.exit", "suspend");
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");	
				//mementoSerialized = scorm.get("cmi.suspend_data");
				var stringScore:String = scorm.get("cmi.score.raw");
				
				switch(status)
				{
					// Primeiro acesso à AI
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						break;
					
					// Continuando a AI...
					case "incomplete":
						completed = false;
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						//setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				
				//unmarshalObjects(mementoSerialized);
				scormExercise = 1;
				score = Number(stringScore.replace(",", "."));
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					pingTimer.start();
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				trace("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
				mementoSerialized = ExternalInterface.call("getLocalStorageString");
			}
			
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function commit()
		{
			if (connected)
			{
				if (scorm.get("cmi.mode") != "normal") return;
				
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());
				
				// Salva no LMS a string que representa a situação atual da AI para ser recuperada posteriormente.
				//mementoSerialized = marshalObjects();
				//success = scorm.set("cmi.suspend_data", mementoSerialized.toString());

				if (success)
				{
					scorm.save();
				}
				else
				{
					pingTimer.stop();
					//setMessage("Falha na conexão com o LMS.");
					connected = false;
				}
			}else { //LocalStorage
				//ExternalInterface.call("save2LS", mementoSerialized);
			}
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent)
		{
			//scorm.get("cmi.completion_status");
			commit();
		}
		
		private function saveStatus(e:Event = null):void
		{
			if (ExternalInterface.available) {
				
				if (scorm.get("cmi.mode") != "normal") return;
				
				//saveStatusForRecovery();
				if (connected) {
					scorm.set("cmi.suspend_data", mementoSerialized);
					commit();
				}else {//LocalStorage
					ExternalInterface.call("save2LS", mementoSerialized);
				}
			}
		}
	}
}