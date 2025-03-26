<script lang="ts">
	import 'css/main.css';
	import { each } from 'lodash-es';
	import { onMount } from 'svelte';
	import { Pane, Slider, ThemeUtils } from 'svelte-tweakpane-ui';
	import {
		Clock,
		Color,
		GLSL3,
		MathUtils,
		Mesh,
		NearestFilter,
		PerspectiveCamera,
		PlaneGeometry,
		Scene,
		ShaderMaterial,
		TextureLoader,
		WebGLRenderer
	} from 'three';
	import fragmentShader from './glsl/fragment.glsl';
	import vertexShader from './glsl/vertex.glsl';
	import type { StageSize } from './types';

	//----- Vars

	let clock: Clock;
	let renderer: WebGLRenderer;
	let scene: Scene;
	let camera: PerspectiveCamera;
	let wrapperEl: HTMLElement;

	const loader: TextureLoader = new TextureLoader();

	let stageScale: StageSize;
	let textureRatio: number;
	let quad: Mesh;
	let material: ShaderMaterial;

	let progress = 0;

	//----- Methods

	const initThree = () => {
		renderer = new WebGLRenderer({
			alpha: false,
			antialias: true
		});
		renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
		wrapperEl.appendChild(renderer.domElement);
	};

	const initScene = async () => {
		const color = new Color('#222');

		//Scene Config
		scene = new Scene();
		scene.background = color;

		camera = new PerspectiveCamera(
			50,
			renderer.domElement.offsetWidth / renderer.domElement.offsetHeight,
			0.1,
			50
		);
		camera.position.z = 5;

		stageScale = calculateUnitSize(camera.position.z, camera);

		//start a threejs clock
		clock = new Clock(true);

		//--- add temp
		await build();
	};

	const build = async () => {
		const first = await loader.loadAsync('/textures/first.jpg');
		const second = await loader.loadAsync('/textures/second.jpg');
		const mask = await loader.loadAsync('/textures/mask.jpg');

		each([first, second, mask], (t) => {
			t.generateMipmaps = false;
			t.minFilter = t.magFilter = NearestFilter;
		});

		//all textures have the same ratio
		textureRatio = first.image.width / first.image.height;

		material = new ShaderMaterial({
			uniforms: {
				uFirstTexture: { value: first },
				uSecondTexture: { value: second },
				uMaskTexture: { value: mask },
				uCropV: { value: 0 },
				uCropH: { value: 0 },
				uProgress: { value: progress }
			},
			glslVersion: GLSL3,
			vertexShader,
			fragmentShader
		});

		quad = new Mesh(new PlaneGeometry(1, 1), material);
		scene.add(quad);
	};

	const render = () => {
		requestAnimationFrame(render);
		renderer.render(scene, camera);

		const delta = clock.getDelta();
		material.uniforms.uProgress.value = MathUtils.damp(
			material.uniforms.uProgress.value,
			progress,
			5,
			delta
		);
	};

	const resize = () => {
		renderer.setSize(window.innerWidth, window.innerHeight);

		camera.aspect = renderer.domElement.offsetWidth / renderer.domElement.offsetHeight;
		camera.updateProjectionMatrix();

		stageScale = calculateUnitSize(camera.position.z, camera);

		const stageRatio = stageScale.width / stageScale.height;

		let diff;

		// vertical or paysage
		if (stageRatio > textureRatio) {
			quad.scale.set(stageScale.width, stageScale.width / textureRatio, 1);

			diff = stageScale.height - quad.scale.y;
			material.uniforms.uCropH.value = 0;
			material.uniforms.uCropV.value = worldToUV(diff, quad.scale.y, 1 / textureRatio) * 0.75;
		} else {
			quad.scale.set(stageScale.height * textureRatio, stageScale.height, 1);

			diff = stageScale.width - quad.scale.x;
			material.uniforms.uCropV.value = 0;
			material.uniforms.uCropH.value = worldToUV(diff, quad.scale.x, 1 / textureRatio) * 0.75;
		}
	};

	//----- Utils Methods

	const worldToUV = (worldOffset: number, planeSize: number, textureSize: number): number => {
		return worldOffset / (planeSize / textureSize);
	};

	const calculateUnitSize = (distance: number, camera: PerspectiveCamera): StageSize => {
		const vFov = camera.fov * (Math.PI / 180);
		const height = 2 * Math.tan(vFov / 2) * distance;
		const width = height * camera.aspect;

		return { width, height };
	};

	//----- Event Handlers

	//----- Lifecycle

	onMount(async () => {
		initThree();
		await initScene();

		resize();
		render();
	});
</script>

<svelte:window on:resize={resize} />

<div bind:this={wrapperEl} id="threejs-wrapper" class="fixed top-0 left-0 h-full w-full"></div>
<div class="fixed top-2 right-2">
	<Pane theme={ThemeUtils.presets.iceberg}>
		<Slider min={0} max={1} bind:value={progress} step={0.01} label="Progress" />
	</Pane>
</div>
